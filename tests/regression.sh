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

main() {
  test_install_urls
  test_relative_bin_with_cwd
}

main "$@"
