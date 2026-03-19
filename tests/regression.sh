#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

assert_contains_count() {
  local file_path="$1"
  local needle="$2"
  local expected_count="$3"
  local actual_count=""

  actual_count="$(grep -F -c "$needle" "$file_path" || true)"
  [[ "$actual_count" == "$expected_count" ]] || fail "$file_path expected $expected_count occurrences of: $needle (found $actual_count)"
}

assert_not_contains() {
  local file_path="$1"
  local needle="$2"

  if grep -F -q "$needle" "$file_path"; then
    fail "$file_path unexpectedly contains: $needle"
  fi
}

test_install_urls() {
  local raw_url="https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh"
  local repo_url="https://github.com/e2enetworks-oss/e2enetworks-skills.git"

  assert_contains_count "$repo_root/README.md" "$raw_url" 4
  assert_contains_count "$repo_root/README.md" "$repo_url" 4
  assert_contains_count "$repo_root/rfc.md" "$raw_url" 3
  assert_contains_count "$repo_root/rfc.md" "$repo_url" 3
  assert_contains_count "$repo_root/scripts/install.sh" "$raw_url" 1
  assert_contains_count "$repo_root/scripts/install.sh" "$repo_url" 1

  assert_not_contains "$repo_root/README.md" "<OWNER>/<REPO>"
  assert_not_contains "$repo_root/README.md" "<ORG>"
  assert_not_contains "$repo_root/rfc.md" "<OWNER>/<REPO>"
  assert_not_contains "$repo_root/rfc.md" "REPLACE_ME"

  pass "install URLs stay pinned to the official repository"
}

test_claude_install_path() {
  local tmp_dir=""
  local claude_home=""

  tmp_dir="$(mktemp -d)"
  claude_home="$tmp_dir/.claude"

  "$repo_root/scripts/install.sh" --target claude --repo-dir "$repo_root" --claude-home "$claude_home" --force >/dev/null

  [[ -f "$claude_home/skills/use-e2e/SKILL.md" ]] || fail "expected Claude install to create $claude_home/skills/use-e2e/SKILL.md"
  [[ ! -e "$claude_home/plugins/e2e" ]] || fail "expected Claude install not to write legacy plugin path $claude_home/plugins/e2e"

  rm -rf "$tmp_dir"

  pass "Claude installs into the direct skills directory"
}

test_claude_skill_allowed_tools() {
  local skill_file="$repo_root/plugins/e2e/skills/use-e2e/SKILL.md"

  grep -F -q 'allowed-tools: Read, Grep, Glob, Bash(e2ectl *), Bash(hitesh-test *), Bash(npx e2ectl *), Bash(npx hitesh-test *)' "$skill_file" || \
    fail "expected Claude skill to pre-allow the e2ectl and hitesh-test command patterns"

  pass "Claude skill pre-allows the E2E CLI command patterns"
}

test_relative_bin_with_cwd() {
  local script_path="$repo_root/plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh"
  local tmp_dir=""
  local project_dir=""
  local output=""
  local rc=0

  tmp_dir="$(mktemp -d)"
  project_dir="$tmp_dir/project"
  mkdir -p "$project_dir/bin"

  printf '%s\n' '#!/usr/bin/env bash' 'echo EXPLICIT_BIN_OK' > "$project_dir/bin/e2ectl"
  chmod +x "$project_dir/bin/e2ectl"

  pushd /tmp >/dev/null
  set +e
  output="$("$script_path" --cwd "$project_dir" --bin ./bin/e2ectl -- noop 2>&1)"
  rc=$?
  set -e
  popd >/dev/null

  [[ "$rc" == "0" ]] || fail "expected explicit relative --bin under --cwd to succeed, got exit code $rc with output: $output"
  [[ "$output" == "EXPLICIT_BIN_OK" ]] || fail "expected explicit relative --bin output to be EXPLICIT_BIN_OK, got: $output"

  rm -rf "$tmp_dir"

  pass "explicit relative --bin resolves against --cwd"
}

test_local_cli_beats_global_cli_under_cwd() {
  local script_path="$repo_root/plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh"
  local tmp_dir=""
  local project_dir=""
  local global_dir=""
  local output=""

  tmp_dir="$(mktemp -d)"
  project_dir="$tmp_dir/project"
  global_dir="$tmp_dir/global"
  mkdir -p "$project_dir/node_modules/.bin" "$global_dir"

  printf '%s\n' '#!/usr/bin/env bash' 'echo LOCAL_HITESH' > "$project_dir/node_modules/.bin/hitesh-test"
  chmod +x "$project_dir/node_modules/.bin/hitesh-test"
  printf '%s\n' '#!/usr/bin/env bash' 'echo GLOBAL_E2ECTL' > "$global_dir/e2ectl"
  chmod +x "$global_dir/e2ectl"

  output="$(PATH="$global_dir:/usr/bin:/bin:/usr/sbin:/sbin" "$script_path" --cwd "$project_dir" -- noop)"

  [[ "$output" == "LOCAL_HITESH" ]] || fail "expected project-local CLI to beat global CLI under --cwd, got: $output"

  rm -rf "$tmp_dir"

  pass "project-local CLI beats global CLI when --cwd is set"
}

test_relative_env_file_with_cwd() {
  local script_path="$repo_root/plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh"
  local tmp_dir=""
  local project_dir=""
  local source_dir=""
  local output=""

  tmp_dir="$(mktemp -d)"
  project_dir="$tmp_dir/project"
  source_dir="$tmp_dir/source"
  mkdir -p "$project_dir" "$source_dir"
  printf 'EXPORTED_FROM_ENV=from-file\n' > "$source_dir/test.env"

  pushd "$source_dir" >/dev/null
  output="$("$script_path" --env-file ./test.env --cwd "$project_dir" --bin bash -- -lc 'printf "%s\n" "$EXPORTED_FROM_ENV"')"
  popd >/dev/null

  [[ "$output" == "from-file" ]] || fail "expected relative --env-file under --cwd to export from-file, got: $output"

  rm -rf "$tmp_dir"

  pass "relative --env-file resolves before changing into --cwd"
}

test_bad_env_file_fails_fast() {
  local script_path="$repo_root/plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh"
  local tmp_dir=""
  local project_dir=""
  local source_dir=""
  local output=""
  local rc=0

  tmp_dir="$(mktemp -d)"
  project_dir="$tmp_dir/project"
  source_dir="$tmp_dir/source"
  mkdir -p "$project_dir" "$source_dir"
  printf 'definitely_not_a_command\n' > "$source_dir/bad.env"

  pushd "$source_dir" >/dev/null
  set +e
  output="$("$script_path" --env-file ./bad.env --cwd "$project_dir" --bin bash -- -lc 'echo SHOULD_NOT_RUN' 2>&1)"
  rc=$?
  set -e
  popd >/dev/null

  [[ "$rc" != "0" ]] || fail "expected bad env file to fail fast, but command exited 0"
  [[ "$output" == *"Error: failed to load --env-file:"* ]] || fail "expected bad env file failure message, got: $output"
  [[ "$output" != *"SHOULD_NOT_RUN"* ]] || fail "wrapped command ran despite env-file failure: $output"

  rm -rf "$tmp_dir"

  pass "bad --env-file aborts before running the wrapped command"
}

main() {
  test_install_urls
  test_claude_install_path
  test_claude_skill_allowed_tools
  test_relative_bin_with_cwd
  test_local_cli_beats_global_cli_under_cwd
  test_relative_env_file_with_cwd
  test_bad_env_file_fails_fast
}

main "$@"
