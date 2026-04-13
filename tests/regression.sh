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

cleanup_dir() {
  local dir_path="$1"

  if [[ -n "$dir_path" && -d "$dir_path" ]]; then
    rm -rf "$dir_path"
  fi
}

write_minimal_skill_repo() {
  local repo_dir="$1"
  local marker="$2"

  mkdir -p "$repo_dir/plugins/e2e/skills/use-e2e"
  cat > "$repo_dir/plugins/e2e/skills/use-e2e/SKILL.md" <<EOF
# $marker
EOF
}

create_remote_repo_fixture() {
  local fixture_root="$1"
  local commit_sha_file="$fixture_root/commit-sha.txt"
  local repo_dir="$fixture_root/remote-repo"

  mkdir -p "$repo_dir"
  git init -b main "$repo_dir" >/dev/null
  git -C "$repo_dir" config user.name "Regression"
  git -C "$repo_dir" config user.email "regression@example.com"

  write_minimal_skill_repo "$repo_dir" "COMMIT_REF"
  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "commit ref" >/dev/null
  git -C "$repo_dir" rev-parse HEAD > "$commit_sha_file"

  write_minimal_skill_repo "$repo_dir" "TAG_REF"
  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "tag ref" >/dev/null
  git -C "$repo_dir" tag v1.2.3

  git -C "$repo_dir" checkout -b feature-branch >/dev/null
  write_minimal_skill_repo "$repo_dir" "BRANCH_REF"
  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "branch ref" >/dev/null

  git -C "$repo_dir" checkout main >/dev/null
  write_minimal_skill_repo "$repo_dir" "MAIN_REF"
  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "main ref" >/dev/null

  printf 'file://%s\n' "$repo_dir"
}

create_cli_stub_dir() {
  local stub_dir="$1"

  mkdir -p "$stub_dir"

  cat > "$stub_dir/npm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${FAKE_NPM_LOG:-}" ]]; then
  printf '%s\n' "$*" >> "$FAKE_NPM_LOG"
fi

if [[ "${1:-}" == "view" && "${2:-}" == "@e2enetworks-oss/e2ectl" && "${3:-}" == "version" ]]; then
  if [[ "${FAKE_NPM_VIEW_FAIL:-0}" == "1" ]]; then
    printf 'npm view failed\n' >&2
    exit 1
  fi

  printf '%s\n' "${FAKE_NPM_LATEST_VERSION:-0.0.0}"
  exit 0
fi

if [[ "${1:-}" == "prefix" && "${2:-}" == "-g" ]]; then
  if [[ -n "${FAKE_NPM_GLOBAL_PREFIX:-}" ]]; then
    printf '%s\n' "$FAKE_NPM_GLOBAL_PREFIX"
    exit 0
  fi

  if [[ -n "${FAKE_NPM_INSTALL_TARGET:-}" ]]; then
    printf '%s\n' "$(dirname "$FAKE_NPM_INSTALL_TARGET")"
    exit 0
  fi

  printf '%s\n' "$(cd -- "$(dirname "$0")/.." && pwd -P)"
  exit 0
fi

if [[ "${1:-}" == "install" && "${2:-}" == "-g" && "${3:-}" == "@e2enetworks-oss/e2ectl@latest" ]]; then
  if [[ "${FAKE_NPM_INSTALL_FAIL:-0}" == "1" ]]; then
    if [[ "${FAKE_NPM_INSTALL_ENGINE_FAIL:-0}" == "1" ]]; then
      printf 'npm warn EBADENGINE Unsupported engine {\n' >&2
      printf "npm warn EBADENGINE   package: '@e2enetworks-oss/e2ectl@%s',\n" "${FAKE_NPM_LATEST_VERSION:-0.0.0}" >&2
      printf "npm warn EBADENGINE   required: { node: '%s' },\n" "${FAKE_NPM_REQUIRED_NODE:-unknown}" >&2
      printf "npm warn EBADENGINE   current: { node: 'v%s', npm: '10.9.3' }\n" "${FAKE_NODE_VERSION:-0.0.0}" >&2
      printf 'npm warn EBADENGINE }\n' >&2
      printf 'npm error code EEXIST\n' >&2
      printf 'npm error path %s/e2ectl\n' "${FAKE_NPM_INSTALL_TARGET:-/fake/bin}" >&2
      printf 'npm error EEXIST: file already exists\n' >&2
    else
      printf 'npm install failed\n' >&2
    fi
    exit 1
  fi

  if [[ -n "${FAKE_NPM_INSTALL_TARGET:-}" ]]; then
    mkdir -p "$FAKE_NPM_INSTALL_TARGET"
    cat > "$FAKE_NPM_INSTALL_TARGET/e2ectl" <<'INNER'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--version" ]]; then
  printf 'e2ectl %s\n' "${FAKE_NPM_INSTALLED_VERSION:-${FAKE_NPM_LATEST_VERSION:-0.0.0}}"
  exit 0
fi

printf '%s\n' "${FAKE_E2ECTL_OUTPUT:-FAKE_E2ECTL}"
INNER
    chmod +x "$FAKE_NPM_INSTALL_TARGET/e2ectl"
  fi

  exit 0
fi

printf 'unexpected npm args: %s\n' "$*" >&2
exit 1
EOF
  chmod +x "$stub_dir/npm"
}

write_fake_e2ectl() {
  local stub_dir="$1"

  cat > "$stub_dir/e2ectl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--version" ]]; then
  printf 'e2ectl %s\n' "${FAKE_E2ECTL_VERSION:-0.0.0}"
  exit 0
fi

printf '%s\n' "${FAKE_E2ECTL_OUTPUT:-FAKE_E2ECTL}"
EOF
  chmod +x "$stub_dir/e2ectl"
}

installer_path_env() {
  local stub_dir="$1"

  printf '%s:/usr/bin:/bin:/usr/sbin:/sbin\n' "$stub_dir"
}

run_installer_with_stubs() {
  local stub_dir="$1"
  shift

  env \
    PATH="$(installer_path_env "$stub_dir")" \
    FAKE_NPM_LOG="${FAKE_NPM_LOG:-}" \
    FAKE_NPM_LATEST_VERSION="${FAKE_NPM_LATEST_VERSION:-}" \
    FAKE_NPM_VIEW_FAIL="${FAKE_NPM_VIEW_FAIL:-}" \
    FAKE_NPM_INSTALL_FAIL="${FAKE_NPM_INSTALL_FAIL:-}" \
    FAKE_NPM_INSTALL_ENGINE_FAIL="${FAKE_NPM_INSTALL_ENGINE_FAIL:-}" \
    FAKE_NPM_GLOBAL_PREFIX="${FAKE_NPM_GLOBAL_PREFIX:-}" \
    FAKE_NPM_INSTALL_TARGET="${FAKE_NPM_INSTALL_TARGET:-}" \
    FAKE_NPM_INSTALLED_VERSION="${FAKE_NPM_INSTALLED_VERSION:-}" \
    FAKE_NPM_REQUIRED_NODE="${FAKE_NPM_REQUIRED_NODE:-}" \
    FAKE_NODE_VERSION="${FAKE_NODE_VERSION:-}" \
    FAKE_E2ECTL_VERSION="${FAKE_E2ECTL_VERSION:-}" \
    FAKE_E2ECTL_OUTPUT="${FAKE_E2ECTL_OUTPUT:-}" \
    bash "$repo_root/scripts/install.sh" "$@"
}

run_installer_via_stdin_with_stubs() {
  local stub_dir="$1"
  shift

  (
    env \
      PATH="$(installer_path_env "$stub_dir")" \
      FAKE_NPM_LOG="${FAKE_NPM_LOG:-}" \
      FAKE_NPM_LATEST_VERSION="${FAKE_NPM_LATEST_VERSION:-}" \
      FAKE_NPM_VIEW_FAIL="${FAKE_NPM_VIEW_FAIL:-}" \
      FAKE_NPM_INSTALL_FAIL="${FAKE_NPM_INSTALL_FAIL:-}" \
      FAKE_NPM_INSTALL_ENGINE_FAIL="${FAKE_NPM_INSTALL_ENGINE_FAIL:-}" \
      FAKE_NPM_GLOBAL_PREFIX="${FAKE_NPM_GLOBAL_PREFIX:-}" \
      FAKE_NPM_INSTALL_TARGET="${FAKE_NPM_INSTALL_TARGET:-}" \
      FAKE_NPM_INSTALLED_VERSION="${FAKE_NPM_INSTALLED_VERSION:-}" \
      FAKE_NPM_REQUIRED_NODE="${FAKE_NPM_REQUIRED_NODE:-}" \
      FAKE_NODE_VERSION="${FAKE_NODE_VERSION:-}" \
      FAKE_E2ECTL_VERSION="${FAKE_E2ECTL_VERSION:-}" \
      FAKE_E2ECTL_OUTPUT="${FAKE_E2ECTL_OUTPUT:-}" \
      bash -s -- "$@" < "$repo_root/scripts/install.sh"
  )
}

test_install_urls() {
  local raw_url="https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh"
  local repo_url="https://github.com/e2enetworks-oss/e2enetworks-skills.git"

  grep -F -q "$raw_url" "$repo_root/README.md" || fail "expected README to keep the official raw install URL"
  assert_contains_count "$repo_root/rfc.md" "$raw_url" 3
  assert_contains_count "$repo_root/rfc.md" "$repo_url" 3
  assert_contains_count "$repo_root/scripts/install.sh" "$raw_url" 1
  grep -F -q "$repo_url" "$repo_root/scripts/install.sh" || fail "expected installer to keep the official repository URL"

  assert_not_contains "$repo_root/README.md" "<OWNER>/<REPO>"
  assert_not_contains "$repo_root/README.md" "<ORG>"
  assert_not_contains "$repo_root/rfc.md" "<OWNER>/<REPO>"
  assert_not_contains "$repo_root/rfc.md" "REPLACE_ME"

  pass "install URLs stay pinned to the official repository"
}

test_install_script_supported_targets() {
  local install_script="$repo_root/scripts/install.sh"

  grep -F -q 'codex|claude|claude-code|opencode|open-code|amp|all' "$install_script" || \
    fail "expected installer usage text to advertise the simplified target list"
  grep -F -q '[--scope global|project]' "$install_script" || \
    fail "expected installer usage text to advertise install scope selection"
  grep -F -q '[--repo-ref <branch|tag|commit>]' "$install_script" || \
    fail "expected installer usage text to advertise remote ref selection"
  grep -F -q '[--skip-cli] [--upgrade-cli]' "$install_script" || \
    fail "expected installer usage text to advertise CLI lifecycle flags"
  grep -F -q 'official_repo_url="https://github.com/e2enetworks-oss/e2enetworks-skills.git"' "$install_script" || \
    fail "expected installer to default to the official repo URL"
  grep -F -q 'default_remote_ref="main"' "$install_script" || \
    fail "expected installer to default remote installs to the main branch"
  grep -F -q 'Install skills globally or in this project?' "$install_script" || \
    fail "expected installer to prompt for project vs global scope"
  grep -F -q 'A newer stable e2ectl is available' "$install_script" || \
    fail "expected installer to prompt for CLI upgrades in interactive mode"

  pass "installer supports simplified targets, remote refs, and CLI lifecycle flags"
}

test_missing_scope_defaults_to_global_without_tty() {
  local tmp_dir=""
  local claude_home=""
  local stub_dir=""

  tmp_dir="$(mktemp -d)"
  claude_home="$tmp_dir/.claude"
  stub_dir="$tmp_dir/stubs"
  create_cli_stub_dir "$stub_dir"
  write_fake_e2ectl "$stub_dir"

  FAKE_E2ECTL_VERSION=0.3.0 FAKE_NPM_LATEST_VERSION=0.3.0 run_installer_with_stubs "$stub_dir" \
    --target claude \
    --repo-dir "$repo_root" \
    --claude-home "$claude_home" >/dev/null

  [[ -f "$claude_home/skills/use-e2e/SKILL.md" ]] || fail "expected missing --scope to default to a global install"

  cleanup_dir "$tmp_dir"

  pass "installer defaults to global scope outside interactive terminals"
}

test_rerun_updates_existing_install_without_force() {
  local tmp_dir=""
  local repo_one=""
  local repo_two=""
  local claude_home=""
  local installed_skill=""
  local stub_dir=""

  tmp_dir="$(mktemp -d)"
  repo_one="$tmp_dir/repo-one"
  repo_two="$tmp_dir/repo-two"
  claude_home="$tmp_dir/.claude"
  installed_skill="$claude_home/skills/use-e2e/SKILL.md"
  stub_dir="$tmp_dir/stubs"
  create_cli_stub_dir "$stub_dir"
  write_fake_e2ectl "$stub_dir"

  write_minimal_skill_repo "$repo_one" "FIRST_INSTALL"
  write_minimal_skill_repo "$repo_two" "SECOND_INSTALL"

  FAKE_E2ECTL_VERSION=0.3.0 FAKE_NPM_LATEST_VERSION=0.3.0 run_installer_with_stubs "$stub_dir" \
    --target claude \
    --scope global \
    --repo-dir "$repo_one" \
    --claude-home "$claude_home" >/dev/null

  grep -F -q 'FIRST_INSTALL' "$installed_skill" || fail "expected first install marker"

  FAKE_E2ECTL_VERSION=0.3.0 FAKE_NPM_LATEST_VERSION=0.3.0 run_installer_with_stubs "$stub_dir" \
    --target claude \
    --scope global \
    --repo-dir "$repo_two" \
    --claude-home "$claude_home" >/dev/null

  grep -F -q 'SECOND_INSTALL' "$installed_skill" || fail "expected rerun installer to refresh the installed skill"

  cleanup_dir "$tmp_dir"

  pass "rerunning the installer updates an existing install without --force"
}

test_claude_install_path() {
  local tmp_dir=""
  local claude_home=""
  local stub_dir=""

  tmp_dir="$(mktemp -d)"
  claude_home="$tmp_dir/.claude"
  stub_dir="$tmp_dir/stubs"
  create_cli_stub_dir "$stub_dir"
  write_fake_e2ectl "$stub_dir"

  FAKE_E2ECTL_VERSION=0.3.0 FAKE_NPM_LATEST_VERSION=0.3.0 run_installer_with_stubs "$stub_dir" \
    --target claude --scope global --repo-dir "$repo_root" --claude-home "$claude_home" --force >/dev/null

  [[ -f "$claude_home/skills/use-e2e/SKILL.md" ]] || fail "expected Claude install to create $claude_home/skills/use-e2e/SKILL.md"
  [[ -f "$claude_home/commands/use-e2e.md" ]] || fail "expected Claude install to create $claude_home/commands/use-e2e.md"
  grep -F -q "[\$use-e2e]($claude_home/skills/use-e2e/SKILL.md)" "$claude_home/commands/use-e2e.md" || \
    fail "expected Claude command to point at the installed skill path"
  [[ ! -e "$claude_home/plugins/e2e" ]] || fail "expected Claude install not to write legacy plugin path $claude_home/plugins/e2e"

  cleanup_dir "$tmp_dir"

  pass "Claude installs both the direct skill and slash command"
}

test_project_scope_install_path() {
  local tmp_dir=""
  local project_dir=""
  local stub_dir=""
  local installed_skill_path=""

  tmp_dir="$(mktemp -d)"
  project_dir="$tmp_dir/app"
  stub_dir="$tmp_dir/stubs"
  mkdir -p "$project_dir"
  create_cli_stub_dir "$stub_dir"
  write_fake_e2ectl "$stub_dir"

  FAKE_E2ECTL_VERSION=0.3.0 FAKE_NPM_LATEST_VERSION=0.3.0 run_installer_with_stubs "$stub_dir" \
    --target claude \
    --scope project \
    --project-dir "$project_dir" \
    --repo-dir "$repo_root" \
    --force >/dev/null

  [[ -f "$project_dir/.claude/skills/use-e2e/SKILL.md" ]] || \
    fail "expected project scope install to create $project_dir/.claude/skills/use-e2e/SKILL.md"
  [[ -f "$project_dir/.claude/commands/use-e2e.md" ]] || \
    fail "expected project scope install to create $project_dir/.claude/commands/use-e2e.md"
  installed_skill_path="$(cd -- "$project_dir/.claude/skills/use-e2e" && pwd -P)/SKILL.md"
  grep -F -q "[\$use-e2e]($installed_skill_path)" "$project_dir/.claude/commands/use-e2e.md" || \
    fail "expected project Claude command to point at the installed project skill path"

  cleanup_dir "$tmp_dir"

  pass "project scope installs both the vendored project skill and slash command"
}

test_repo_ref_installs_branch_tag_and_commit() {
  local tmp_dir=""
  local repo_url=""
  local commit_sha=""
  local branch_home=""
  local tag_home=""
  local commit_home=""
  local stub_dir=""

  tmp_dir="$(mktemp -d)"
  repo_url="$(create_remote_repo_fixture "$tmp_dir")"
  commit_sha="$(cat "$tmp_dir/commit-sha.txt")"
  branch_home="$tmp_dir/branch-home"
  tag_home="$tmp_dir/tag-home"
  commit_home="$tmp_dir/commit-home"
  stub_dir="$tmp_dir/stubs"
  create_cli_stub_dir "$stub_dir"
  write_fake_e2ectl "$stub_dir"

  FAKE_E2ECTL_VERSION=0.3.0 FAKE_NPM_LATEST_VERSION=0.3.0 run_installer_with_stubs "$stub_dir" \
    --target claude \
    --scope global \
    --repo-url "$repo_url" \
    --repo-ref feature-branch \
    --claude-home "$branch_home" >/dev/null

  grep -F -q 'BRANCH_REF' "$branch_home/skills/use-e2e/SKILL.md" || fail "expected --repo-ref branch install to use branch content"

  FAKE_E2ECTL_VERSION=0.3.0 FAKE_NPM_LATEST_VERSION=0.3.0 run_installer_with_stubs "$stub_dir" \
    --target claude \
    --scope global \
    --repo-url "$repo_url" \
    --repo-ref v1.2.3 \
    --claude-home "$tag_home" >/dev/null

  grep -F -q 'TAG_REF' "$tag_home/skills/use-e2e/SKILL.md" || fail "expected --repo-ref tag install to use tag content"

  FAKE_E2ECTL_VERSION=0.3.0 FAKE_NPM_LATEST_VERSION=0.3.0 run_installer_with_stubs "$stub_dir" \
    --target claude \
    --scope global \
    --repo-url "$repo_url" \
    --repo-ref "$commit_sha" \
    --claude-home "$commit_home" >/dev/null

  grep -F -q 'COMMIT_REF' "$commit_home/skills/use-e2e/SKILL.md" || fail "expected --repo-ref commit install to use commit content"

  cleanup_dir "$tmp_dir"

  pass "--repo-ref installs branch, tag, and commit sources"
}

test_claude_skill_allowed_tools() {
  local skill_file="$repo_root/plugins/e2e/skills/use-e2e/SKILL.md"

  grep -F -q 'Bash(e2ectl *)' "$skill_file" || fail "expected Claude skill to pre-allow e2ectl commands"
  grep -F -q 'Bash(npm *)' "$skill_file" || fail "expected Claude skill to pre-allow npm commands"

  pass "Claude skill pre-allows the e2ectl CLI command patterns"
}

test_internal_docs_capture_hidden_mode_without_prerelease_language() {
  local agents_file="$repo_root/AGENTS.md"

  grep -F -q 'E2E_SKILLS_MODE=internal' "$agents_file" || \
    fail "expected AGENTS.md to keep the hidden internal mode for maintainers"
  assert_not_contains "$agents_file" "hitesh-test"
  assert_not_contains "$agents_file" 'branch `develop`'

  pass "AGENTS.md keeps the hidden internal mode without pre-release package drift"
}

test_skill_docs_match_installed_cli_contract() {
  local skill_file="$repo_root/plugins/e2e/skills/use-e2e/SKILL.md"
  local access_file="$repo_root/plugins/e2e/skills/use-e2e/references/access.md"

  grep -F -q '@e2enetworks-oss/e2ectl' "$skill_file" || fail "expected SKILL.md to document the official npm package"
  grep -F -q 'npm install -g @e2enetworks-oss/e2ectl' "$access_file" || \
    fail "expected access reference to document installing the official npm package"

  pass "skill docs describe installing the official @e2enetworks-oss/e2ectl package"
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
  output="$(bash "$script_path" --cwd "$project_dir" --bin ./bin/e2ectl -- noop 2>&1)"
  rc=$?
  set -e
  popd >/dev/null

  [[ "$rc" == "0" ]] || fail "expected explicit relative --bin under --cwd to succeed, got exit code $rc with output: $output"
  [[ "$output" == "EXPLICIT_BIN_OK" ]] || fail "expected explicit relative --bin output to be EXPLICIT_BIN_OK, got: $output"

  cleanup_dir "$tmp_dir"

  pass "explicit relative --bin resolves against --cwd"
}

test_public_mode_prefers_installed_e2ectl() {
  local script_path="$repo_root/plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh"
  local tmp_dir=""
  local project_dir=""
  local global_dir=""
  local output=""

  tmp_dir="$(mktemp -d)"
  project_dir="$tmp_dir/project"
  global_dir="$tmp_dir/global"
  mkdir -p "$project_dir/node_modules/.bin" "$global_dir"

  printf '%s\n' '#!/usr/bin/env bash' 'echo LOCAL_E2ECTL' > "$project_dir/node_modules/.bin/e2ectl"
  chmod +x "$project_dir/node_modules/.bin/e2ectl"
  printf '%s\n' '#!/usr/bin/env bash' 'echo GLOBAL_E2ECTL' > "$global_dir/e2ectl"
  chmod +x "$global_dir/e2ectl"

  output="$(PATH="$global_dir:/usr/bin:/bin:/usr/sbin:/sbin" bash "$script_path" --cwd "$project_dir" -- noop)"

  [[ "$output" == "LOCAL_E2ECTL" ]] || fail "expected project-local CLI to beat global CLI under --cwd, got: $output"

  cleanup_dir "$tmp_dir"

  pass "public mode prefers installed e2ectl over cwd-local bins"
}

test_public_mode_missing_e2ectl_shows_guidance() {
  local script_path="$repo_root/plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh"
  local output=""
  local rc=0

  set +e
  output="$(PATH="/usr/bin:/bin:/usr/sbin:/sbin" bash "$script_path" -- config list 2>&1)"
  rc=$?
  set -e

  [[ "$rc" != "0" ]] || fail "expected missing e2ectl to fail in public mode"
  [[ "$output" == *"Rerun the installer to install or update it"* ]] || \
    fail "expected rerun-installer guidance for missing public e2ectl, got: $output"

  pass "public mode points users back to the installer when e2ectl is missing"
}

test_internal_mode_prefers_repo_checkout() {
  local script_path="$repo_root/plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh"
  local tmp_dir=""
  local project_dir=""
  local global_dir=""
  local node_dir=""
  local output=""

  tmp_dir="$(mktemp -d)"
  project_dir="$tmp_dir/e2ectl"
  global_dir="$tmp_dir/global"
  mkdir -p "$project_dir/dist/app" "$global_dir"

  cat > "$project_dir/package.json" <<'EOF'
{
  "name": "@e2enetworks-oss/e2ectl"
}
EOF

  cat > "$project_dir/dist/app/index.js" <<'EOF'
#!/usr/bin/env node
console.log('REPO_BUILD_OK');
EOF

  printf '%s\n' '#!/usr/bin/env bash' 'echo GLOBAL_E2ECTL' > "$global_dir/e2ectl"
  chmod +x "$global_dir/e2ectl"

  node_dir="$(dirname "$(command -v node)")"
  output="$(PATH="$global_dir:$node_dir:/usr/bin:/bin:/usr/sbin:/sbin" E2E_SKILLS_MODE=internal bash "$script_path" --cwd "$project_dir" -- config list)"

  [[ "$output" == "REPO_BUILD_OK" ]] || fail "expected internal mode to prefer the local repo checkout, got: $output"

  cleanup_dir "$tmp_dir"

  pass "internal mode prefers a built repo checkout over the installed CLI"
}

test_internal_mode_falls_back_to_installed_e2ectl() {
  local script_path="$repo_root/plugins/e2e/skills/use-e2e/scripts/e2ectl-run.sh"
  local tmp_dir=""
  local project_dir=""
  local global_dir=""
  local output=""

  tmp_dir="$(mktemp -d)"
  project_dir="$tmp_dir/project"
  global_dir="$tmp_dir/global"
  mkdir -p "$project_dir" "$global_dir"

  printf '%s\n' '#!/usr/bin/env bash' 'echo GLOBAL_E2ECTL' > "$global_dir/e2ectl"
  chmod +x "$global_dir/e2ectl"

  output="$(PATH="$global_dir:/usr/bin:/bin:/usr/sbin:/sbin" E2E_SKILLS_MODE=internal bash "$script_path" --cwd "$project_dir" -- noop)"

  [[ "$output" == "GLOBAL_E2ECTL" ]] || fail "expected internal mode to fall back to installed e2ectl, got: $output"

  cleanup_dir "$tmp_dir"

  pass "internal mode falls back to installed e2ectl when no repo checkout exists"
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
  output="$(bash "$script_path" --env-file ./test.env --cwd "$project_dir" --bin bash -- -lc 'printf "%s\n" "$EXPORTED_FROM_ENV"')"
  popd >/dev/null

  [[ "$output" == "from-file" ]] || fail "expected relative --env-file under --cwd to export from-file, got: $output"

  cleanup_dir "$tmp_dir"

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
  output="$(bash "$script_path" --env-file ./bad.env --cwd "$project_dir" --bin bash -- -lc 'echo SHOULD_NOT_RUN' 2>&1)"
  rc=$?
  set -e
  popd >/dev/null

  [[ "$rc" != "0" ]] || fail "expected bad env file to fail fast, but command exited 0"
  [[ "$output" == *"Error: failed to load --env-file:"* ]] || fail "expected bad env file failure message, got: $output"
  [[ "$output" != *"SHOULD_NOT_RUN"* ]] || fail "wrapped command ran despite env-file failure: $output"

  cleanup_dir "$tmp_dir"

  pass "bad --env-file aborts before running the wrapped command"
}

main() {
  test_install_urls
  test_install_script_supported_targets
  test_missing_scope_defaults_to_global_without_tty
  test_rerun_updates_existing_install_without_force
  test_claude_install_path
  test_project_scope_install_path
  test_repo_ref_installs_branch_tag_and_commit
  test_remote_default_branch_missing_skill_explains_repo_ref
  test_stdin_installer_works_with_remote_source
  test_cli_missing_installs_globally
  test_interactive_cli_upgrade_accepts
  test_interactive_cli_upgrade_declines
  test_interactive_engine_failure_can_continue_with_current_cli
  test_interactive_engine_failure_can_stop_for_node_upgrade
  test_noninteractive_cli_does_not_upgrade_without_flag
  test_failed_upgrade_keeps_existing_cli_and_installs_skill
  test_failed_cli_install_continues_without_cli
  test_noninteractive_upgrade_cli_flag_upgrades
  test_failed_upgrade_verification_keeps_existing_cli_and_installs_skill
  test_failed_upgrade_verification_with_lookup_failure_keeps_existing_cli_and_installs_skill
  test_npm_lookup_failure_with_existing_cli_warns_and_continues
  test_required_cli_install_failure_continues_without_cli
  test_skip_cli_allows_skill_install_without_cli
  test_public_docs_remove_internal_and_prerelease_language
  test_internal_docs_capture_hidden_mode_without_prerelease_language
  test_skill_docs_match_installed_cli_contract
  test_relative_bin_with_cwd
  test_public_mode_prefers_installed_e2ectl
  test_public_mode_missing_e2ectl_shows_guidance
  test_internal_mode_prefers_repo_checkout
  test_internal_mode_falls_back_to_installed_e2ectl
  test_relative_env_file_with_cwd
  test_bad_env_file_fails_fast
}

main "$@"
