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
  grep -F -q 'official_repo_url="https://github.com/e2enetworks-oss/e2enetworks-skills.git"' "$install_script" || \
    fail "expected installer to default to the official repo URL"
  grep -F -q 'default_remote_ref="main"' "$install_script" || \
    fail "expected installer to default remote installs to the main branch"
  grep -F -q 'Install skills globally or in this project?' "$install_script" || \
    fail "expected installer to prompt for project vs global scope"

  pass "installer supports simplified targets and advanced remote refs"
}

test_missing_scope_defaults_to_global_without_tty() {
  local tmp_dir=""
  local claude_home=""

  tmp_dir="$(mktemp -d)"
  claude_home="$tmp_dir/.claude"

  bash "$repo_root/scripts/install.sh" \
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

  tmp_dir="$(mktemp -d)"
  repo_one="$tmp_dir/repo-one"
  repo_two="$tmp_dir/repo-two"
  claude_home="$tmp_dir/.claude"
  installed_skill="$claude_home/skills/use-e2e/SKILL.md"

  write_minimal_skill_repo "$repo_one" "FIRST_INSTALL"
  write_minimal_skill_repo "$repo_two" "SECOND_INSTALL"

  bash "$repo_root/scripts/install.sh" \
    --target claude \
    --scope global \
    --repo-dir "$repo_one" \
    --claude-home "$claude_home" >/dev/null

  grep -F -q 'FIRST_INSTALL' "$installed_skill" || fail "expected first install marker"

  bash "$repo_root/scripts/install.sh" \
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

  tmp_dir="$(mktemp -d)"
  claude_home="$tmp_dir/.claude"

  bash "$repo_root/scripts/install.sh" --target claude --scope global --repo-dir "$repo_root" --claude-home "$claude_home" --force >/dev/null

  [[ -f "$claude_home/skills/use-e2e/SKILL.md" ]] || fail "expected Claude install to create $claude_home/skills/use-e2e/SKILL.md"
  [[ ! -e "$claude_home/plugins/e2e" ]] || fail "expected Claude install not to write legacy plugin path $claude_home/plugins/e2e"

  cleanup_dir "$tmp_dir"

  pass "Claude installs into the direct skills directory"
}

test_project_scope_install_path() {
  local tmp_dir=""
  local project_dir=""

  tmp_dir="$(mktemp -d)"
  project_dir="$tmp_dir/app"
  mkdir -p "$project_dir"

  bash "$repo_root/scripts/install.sh" \
    --target claude \
    --scope project \
    --project-dir "$project_dir" \
    --repo-dir "$repo_root" \
    --force >/dev/null

  [[ -f "$project_dir/.claude/skills/use-e2e/SKILL.md" ]] || \
    fail "expected project scope install to create $project_dir/.claude/skills/use-e2e/SKILL.md"

  cleanup_dir "$tmp_dir"

  pass "project scope installs into the vendored project skill path"
}

test_repo_ref_installs_branch_tag_and_commit() {
  local tmp_dir=""
  local repo_url=""
  local commit_sha=""
  local branch_home=""
  local tag_home=""
  local commit_home=""

  tmp_dir="$(mktemp -d)"
  repo_url="$(create_remote_repo_fixture "$tmp_dir")"
  commit_sha="$(cat "$tmp_dir/commit-sha.txt")"
  branch_home="$tmp_dir/branch-home"
  tag_home="$tmp_dir/tag-home"
  commit_home="$tmp_dir/commit-home"

  bash "$repo_root/scripts/install.sh" \
    --target claude \
    --scope global \
    --repo-url "$repo_url" \
    --repo-ref feature-branch \
    --claude-home "$branch_home" >/dev/null

  grep -F -q 'BRANCH_REF' "$branch_home/skills/use-e2e/SKILL.md" || fail "expected --repo-ref branch install to use branch content"

  bash "$repo_root/scripts/install.sh" \
    --target claude \
    --scope global \
    --repo-url "$repo_url" \
    --repo-ref v1.2.3 \
    --claude-home "$tag_home" >/dev/null

  grep -F -q 'TAG_REF' "$tag_home/skills/use-e2e/SKILL.md" || fail "expected --repo-ref tag install to use tag content"

  bash "$repo_root/scripts/install.sh" \
    --target claude \
    --scope global \
    --repo-url "$repo_url" \
    --repo-ref "$commit_sha" \
    --claude-home "$commit_home" >/dev/null

  grep -F -q 'COMMIT_REF' "$commit_home/skills/use-e2e/SKILL.md" || fail "expected --repo-ref commit install to use commit content"

  cleanup_dir "$tmp_dir"

  pass "--repo-ref installs branch, tag, and commit sources"
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

  printf '%s\n' '#!/usr/bin/env bash' 'echo LOCAL_PROJECT_BIN' > "$project_dir/node_modules/.bin/e2ectl"
  chmod +x "$project_dir/node_modules/.bin/e2ectl"
  printf '%s\n' '#!/usr/bin/env bash' 'echo GLOBAL_E2ECTL' > "$global_dir/e2ectl"
  chmod +x "$global_dir/e2ectl"

  output="$(PATH="$global_dir:/usr/bin:/bin:/usr/sbin:/sbin" bash "$script_path" --cwd "$project_dir" -- noop)"

  [[ "$output" == "GLOBAL_E2ECTL" ]] || fail "expected public mode to use installed e2ectl, got: $output"

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
  test_relative_bin_with_cwd
  test_public_mode_prefers_installed_e2ectl
  test_public_mode_missing_e2ectl_shows_guidance
  test_internal_mode_prefers_repo_checkout
  test_internal_mode_falls_back_to_installed_e2ectl
  test_relative_env_file_with_cwd
  test_bad_env_file_fails_fast
}

main "$@"
