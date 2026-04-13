#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Install e2enetworks-skills into Codex, Claude Code, OpenCode, or Amp.
Installs only the skill pack. The e2ectl CLI is installed on first use of the
use-e2e skill, which will prompt for global or project-local install.

Usage:
  install.sh [--target codex|claude|claude-code|opencode|open-code|amp|all] [--repo-url <git-url>] [--repo-dir <path>] [--codex-home <path>] [--claude-home <path>] [--opencode-home <path>]

Options:
  --target      Install target (default: all)
  --repo-url    Git URL to clone when script runs via curl pipe (default: official repo)
  --repo-dir    Local repo directory containing plugins/e2e
  --codex-home  Codex home (default: $CODEX_HOME or ~/.codex)
  --claude-home Claude home (default: $CLAUDE_HOME or ~/.claude)
  --opencode-home OpenCode config dir (default: $OPENCODE_HOME or ~/.config/opencode)
  -h, --help    Show this help

Examples:
  ./scripts/install.sh
  ./scripts/install.sh --target amp
  curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | bash
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

warn() {
  printf 'Warning: %s\n' "$1" >&2
}

fail_missing_skill_source() {
  local skill_path="$1"

  if [[ "$source_label" == "remote repo" ]]; then
    fail "missing skill source: $skill_path. This installer cloned the remote default branch. If you meant a branch, tag, or commit, rerun with --repo-ref <that-ref>."
  fi

  if [[ "$source_label" == "remote repo ($default_remote_ref)" && "$repo_url" == "$official_repo_url" ]]; then
    fail "missing skill source: $skill_path. This installer cloned $default_remote_ref. If you downloaded install.sh from a branch, tag, or commit URL, rerun with --repo-ref <that-ref>."
  fi

  fail "missing skill source: $skill_path"
}

resolve_dir_path() {
  (
    cd "$1" >/dev/null 2>&1 || exit 1
    pwd -P
  )
}

resolve_script_dir() {
  local script_source=""

  script_source="${BASH_SOURCE:-}"
  if [[ -n "$script_source" && "$script_source" != "bash" && "$script_source" != "-bash" ]]; then
    resolve_dir_path "$(dirname -- "$script_source")"
    return 0
  fi

  if [[ "$0" == */* ]]; then
    resolve_dir_path "$(dirname -- "$0")"
    return 0
  fi

  return 1
}

open_tty_fd() {
  local tty_fd=""

  exec {tty_fd}<> /dev/tty || return 1
  printf '%s\n' "$tty_fd"
}

prompt_choice() {
  local prompt_text="$1"
  local default_value="$2"
  local response=""
  local tty_fd=""

  if [[ -t 0 && -t 1 ]]; then
    printf '%s' "$prompt_text" >&2
    IFS= read -r response || true
  elif tty_fd="$(open_tty_fd 2>/dev/null)"; then
    printf '%s' "$prompt_text" >&"$tty_fd"
    IFS= read -r response <&"$tty_fd" || true
    exec {tty_fd}>&-
    exec {tty_fd}<&-
  else
    return 2
  fi

  response="${response#"${response%%[![:space:]]*}"}"
  response="${response%"${response##*[![:space:]]}"}"

  if [[ -z "$response" ]]; then
    printf '%s\n' "$default_value"
    return 0
  fi

  printf '%s\n' "$response"
}

prompt_yes_no() {
  local prompt_text="$1"
  local default_value="${2:-n}"
  local response=""
  local tty_fd=""

  if [[ -t 0 && -t 1 ]]; then
    printf '%s' "$prompt_text" >&2
    IFS= read -r response || true
  elif tty_fd="$(open_tty_fd 2>/dev/null)"; then
    printf '%s' "$prompt_text" >&"$tty_fd"
    IFS= read -r response <&"$tty_fd" || true
    exec {tty_fd}>&-
    exec {tty_fd}<&-
  else
    return 2
  fi

  response="${response#"${response%%[![:space:]]*}"}"
  response="${response%"${response##*[![:space:]]}"}"

  if [[ -z "$response" ]]; then
    response="$default_value"
  fi

  case "$response" in
    y|Y|yes|YES|Yes)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

clone_repo_at_ref() {
  local url="$1"
  local ref="$2"
  local dst="$3"

  if [[ -z "$ref" ]]; then
    git clone --depth 1 "$url" "$dst" >/dev/null
    return 0
  fi

  if git clone --depth 1 --branch "$ref" --single-branch "$url" "$dst" >/dev/null 2>&1; then
    return 0
  fi

  git clone --depth 1 "$url" "$dst" >/dev/null
  (
    cd "$dst" >/dev/null 2>&1 || exit 1
    git fetch --depth 1 origin "$ref" >/dev/null 2>&1 || exit 1
    git checkout --detach FETCH_HEAD >/dev/null 2>&1
  ) || fail "unable to fetch repo ref: $ref"
}

copy_dir() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" ]]; then
    if [[ "$force" == "true" ]]; then
      rm -rf "$dst"
    elif [[ -t 0 && -t 1 ]]; then
      if prompt_yes_no "Existing install found at $dst. Update it now? [Y/n] " "y"; then
        rm -rf "$dst"
      else
        printf 'Skipped existing install: %s\n' "$dst"
        return 0
      fi
    else
      rm -rf "$dst"
    fi
  fi

  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
  printf 'Installed: %s\n' "$dst"
}

copy_file() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" ]]; then
    if [[ "$force" == "true" ]]; then
      rm -rf "$dst"
    elif [[ -t 0 && -t 1 ]]; then
      if prompt_yes_no "Existing install found at $dst. Update it now? [Y/n] " "y"; then
        rm -rf "$dst"
      else
        printf 'Skipped existing install: %s\n' "$dst"
        return 0
      fi
    else
      rm -rf "$dst"
    fi
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  printf 'Installed: %s\n' "$dst"
}

install_claude_command() {
  local skill_path="$1"
  local command_path="$2"
  local tmp_command=""

  tmp_command="$(mktemp)"
  cat > "$tmp_command" <<EOF
---
description: Manage E2E Networks resources with the installed use-e2e skill.
---

[\$use-e2e]($skill_path)

Use the installed \`use-e2e\` skill for this request. It manages E2E Networks nodes, volumes, VPCs, and SSH keys.
EOF

  copy_file "$tmp_command" "$command_path"
  rm -f "$tmp_command"
}

install_amp() {
  local src="$1"
  local -a cmd=(amp skill add "$src" --global --name use-e2e)

  command -v amp >/dev/null 2>&1 || fail "amp is required for --target amp"

  if [[ "$force" == "true" ]]; then
    cmd+=(--overwrite)
  fi

  "${cmd[@]}"
  printf 'Installed: amp skill use-e2e\n'
}

extract_semver() {
  local raw_value="$1"

  printf '%s\n' "$raw_value" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
}

version_is_less_than() {
  local current_version="$1"
  local latest_version="$2"
  local first_version=""

  [[ "$current_version" != "$latest_version" ]] || return 1
  first_version="$(printf '%s\n%s\n' "$current_version" "$latest_version" | sort -V | head -n 1)"
  [[ "$first_version" == "$current_version" ]]
}

read_installed_cli_version() {
  local version_output=""
  local installed_version=""

  version_output="$(e2ectl --version 2>&1)" || return 1
  installed_version="$(extract_semver "$version_output")"
  [[ -n "$installed_version" ]] || return 1

  printf '%s\n' "$installed_version"
}

resolve_installed_cli_path() {
  if command -v e2ectl >/dev/null 2>&1; then
    command -v e2ectl
    return 0
  fi

  return 1
}

resolve_expected_global_cli_path() {
  local global_prefix=""

  global_prefix="$(npm prefix -g 2>/dev/null)" || return 1
  [[ -n "$global_prefix" ]] || return 1

  printf '%s/bin/e2ectl\n' "$global_prefix"
}

fetch_latest_cli_version() {
  local version_output=""
  local latest_version=""

  version_output="$(npm view @e2enetworks-oss/e2ectl version 2>/dev/null)" || return 1
  latest_version="$(extract_semver "$version_output")"
  [[ -n "$latest_version" ]] || return 1

  printf '%s\n' "$latest_version"
}

install_global_cli() {
  npm install -g @e2enetworks-oss/e2ectl@latest
}

extract_install_failure_summary() {
  local raw_output="$1"
  local summary=""

  summary="$(printf '%s\n' "$raw_output" | grep -E '^(npm (error|ERR!|warn)|Error:)' | tail -n 1 || true)"
  if [[ -z "$summary" ]]; then
    summary="$(printf '%s\n' "$raw_output" | awk 'NF { last=$0 } END { print last }')"
  fi

  [[ -n "$summary" ]] || summary="see npm output for details"
  printf '%s\n' "$summary"
}

install_failure_requires_node_upgrade() {
  local raw_output="$1"

  [[ "$raw_output" == *"EBADENGINE"* || "$raw_output" == *"Unsupported engine"* ]]
}

maybe_prompt_for_node_upgrade() {
  local install_output="$1"
  local prompt_result=2

  if ! install_failure_requires_node_upgrade "$install_output"; then
    return 1
  fi

  if prompt_yes_no "This CLI update needs a newer Node version. Upgrade Node and rerun the installer instead? [y/N] " "n"; then
    prompt_result=0
  else
    prompt_result=$?
  fi

  if [[ "$prompt_result" != "0" ]]; then
    return 1
  fi

  fail "upgrade Node and rerun the installer"
}

verify_active_cli() {
  local action_label="$1"
  local expected_version="${2:-}"
  local resolved_path=""
  local expected_path=""
  local active_version=""

  if ! resolved_path="$(resolve_installed_cli_path)"; then
    printf '%s\n' "$action_label completed, but e2ectl is still not available on PATH. This usually means npm installed it under a different global prefix." >&2
    return 1
  fi

  expected_path="$(resolve_expected_global_cli_path 2>/dev/null || true)"
  if [[ -n "$expected_path" && "$resolved_path" != "$expected_path" ]]; then
    printf '%s\n' "$action_label completed, but PATH still resolves e2ectl to $resolved_path instead of $expected_path. This usually means npm updated a different global prefix. Fix your PATH or switch to the correct Node/npm environment, then rerun the installer." >&2
    return 1
  fi

  if ! active_version="$(read_installed_cli_version)"; then
    printf '%s\n' "$action_label completed, but the active e2ectl at $resolved_path did not report a usable version." >&2
    return 1
  fi

  if [[ -n "$expected_version" ]] && version_is_less_than "$active_version" "$expected_version"; then
    printf '%s\n' "$action_label completed, but the active e2ectl on PATH is still $active_version at $resolved_path. This usually means npm updated a different global prefix. Fix your PATH or switch to the correct Node/npm environment, then rerun the installer." >&2
    return 1
  fi

  printf '%s\n' "$active_version"
}

ensure_cli_ready() {
  local cli_present="false"
  local installed_version=""
  local latest_version=""
  local verified_version=""
  local expected_version=""
  local install_output=""
  local install_summary=""
  local existing_cli_version=""

  if [[ "$skip_cli" == "true" ]]; then
    cli_status="skipped (--skip-cli)"
    return 0
  fi

  if command -v e2ectl >/dev/null 2>&1; then
    cli_present="true"
    existing_cli_version="$(read_installed_cli_version 2>/dev/null || true)"
  fi

  if [[ "$upgrade_cli" == "true" ]]; then
    command -v npm >/dev/null 2>&1 || fail "npm is required to upgrade @e2enetworks-oss/e2ectl. Install npm or rerun with --skip-cli."
    expected_version="$(fetch_latest_cli_version 2>/dev/null || true)"
    if ! install_output="$(install_global_cli 2>&1)"; then
      install_summary="$(extract_install_failure_summary "$install_output")"
      maybe_prompt_for_node_upgrade "$install_output" || true
      if [[ -n "$existing_cli_version" ]]; then
        if install_failure_requires_node_upgrade "$install_output"; then
          warn "The CLI could not be updated, so the installer kept your current CLI and finished installing the skill."
        else
          warn "The CLI could not be updated, so the installer kept your current CLI and finished installing the skill. $install_summary"
        fi
        cli_status="kept current CLI"
        return 0
      fi

      if install_failure_requires_node_upgrade "$install_output"; then
        warn "The skill was installed, but the CLI could not be added right now."
      else
        warn "The skill was installed, but the CLI could not be added right now. $install_summary"
      fi
      cli_status="not installed"
      return 0
    fi
    if ! verified_version="$(verify_active_cli "global e2ectl upgrade" "$expected_version" 2>&1)"; then
      if [[ -n "$existing_cli_version" ]]; then
        warn "The CLI could not be updated cleanly, so the installer kept your current CLI and finished installing the skill."
        cli_status="kept current CLI"
        return 0
      fi

      warn "The skill was installed, but the CLI could not be added right now."
      cli_status="not installed"
      return 0
    fi
    cli_status="updated"
    return 0
  fi

  if [[ "$cli_present" == "false" ]]; then
    command -v npm >/dev/null 2>&1 || fail "npm is required to install @e2enetworks-oss/e2ectl globally. Install npm or rerun with --skip-cli."
    expected_version="$(fetch_latest_cli_version 2>/dev/null || true)"
    if ! install_output="$(install_global_cli 2>&1)"; then
      install_summary="$(extract_install_failure_summary "$install_output")"
      maybe_prompt_for_node_upgrade "$install_output" || true
      if install_failure_requires_node_upgrade "$install_output"; then
        warn "The skill was installed, but the CLI could not be added right now."
      else
        warn "The skill was installed, but the CLI could not be added right now. $install_summary"
      fi
      cli_status="not installed"
      return 0
    fi
    if ! verified_version="$(verify_active_cli "global e2ectl install" "$expected_version" 2>&1)"; then
      warn "The skill was installed, but the CLI could not be added right now."
      cli_status="not installed"
      return 0
    fi
    cli_status="installed"
    return 0
  fi

  cli_status="kept current CLI"

  if ! command -v npm >/dev/null 2>&1; then
    warn "npm was not found. Keeping the installed e2ectl."
    return 0
  fi

  if ! installed_version="$(read_installed_cli_version)"; then
    warn "could not determine the installed e2ectl version. Keeping the installed CLI."
    return 0
  fi

  if ! latest_version="$(fetch_latest_cli_version)"; then
    warn "could not check npm for the latest e2ectl version. Keeping the installed CLI."
    return 0
  fi

  if ! version_is_less_than "$installed_version" "$latest_version"; then
    cli_status="kept current CLI"
    return 0
  fi

  local upgrade_prompt_result=0

  if prompt_yes_no "A newer stable e2ectl is available ($installed_version -> $latest_version). Upgrade it now? [Y/n] " "y"; then
    upgrade_prompt_result=0
  else
    upgrade_prompt_result=$?
  fi

  case "$upgrade_prompt_result" in
    0)
      if ! install_output="$(install_global_cli 2>&1)"; then
        install_summary="$(extract_install_failure_summary "$install_output")"
        maybe_prompt_for_node_upgrade "$install_output" || true
        if install_failure_requires_node_upgrade "$install_output"; then
          warn "The CLI could not be updated, so the installer kept your current CLI and finished installing the skill."
        else
          warn "The CLI could not be updated, so the installer kept your current CLI and finished installing the skill. $install_summary"
        fi
        cli_status="kept current CLI"
        return 0
      fi
      if ! verified_version="$(verify_active_cli "global e2ectl upgrade" "$latest_version" 2>&1)"; then
        warn "The CLI could not be updated cleanly, so the installer kept your current CLI and finished installing the skill."
        cli_status="kept current CLI"
        return 0
      fi
      cli_status="updated"
      return 0
      ;;
    1)
      cli_status="kept current CLI"
      return 0
      ;;
  esac

  printf 'A newer stable e2ectl is available (%s -> %s). Rerun the installer interactively or pass --upgrade-cli to upgrade it.\n' "$installed_version" "$latest_version"
  return 0
}

target="all"
repo_url=""
repo_ref=""
repo_dir=""
codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
opencode_home="${OPENCODE_HOME:-$HOME/.config/opencode}"
official_repo_url="https://github.com/e2enetworks-oss/e2enetworks-skills.git"
default_remote_ref="main"
cli_status="not checked"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      target="${2:-}"
      shift 2
      ;;
    --repo-url)
      repo_url="${2:-}"
      shift 2
      ;;
    --repo-ref)
      repo_ref="${2:-}"
      shift 2
      ;;
    --repo-dir)
      repo_dir="${2:-}"
      shift 2
      ;;
    --skip-cli)
      skip_cli="true"
      shift
      ;;
    --upgrade-cli)
      upgrade_cli="true"
      shift
      ;;
    --codex-home)
      codex_home="${2:-}"
      shift 2
      ;;
    --claude-home)
      claude_home="${2:-}"
      shift 2
      ;;
    --opencode-home)
      opencode_home="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

case "$target" in
  claude-code) target="claude" ;;
  open-code) target="opencode" ;;
esac

case "$target" in
  codex|claude|opencode|amp|all) ;;
  *) fail "--target must be one of: codex, claude, claude-code, opencode, open-code, amp, all" ;;
esac

resolve_dir_path() {
  (
    cd "$1" >/dev/null 2>&1 || exit 1
    pwd -P
  )
}

copy_dir() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" ]]; then
    rm -rf "$dst"
  fi

  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
  printf 'Installed: %s\n' "$dst"
}

install_amp() {
  local src="$1"

  command -v amp >/dev/null 2>&1 || fail "amp is required for --target amp"

  amp skill add "$src" --global --name use-e2e --overwrite
  printf 'Installed: amp skill use-e2e\n'
}

script_dir="$(resolve_script_dir 2>/dev/null || true)"
if [[ -n "$script_dir" ]]; then
  candidate_repo="$(cd -- "$script_dir/.." 2>/dev/null && pwd || true)"
else
  candidate_repo=""
fi
source_repo=""
source_label=""
tmp_dir=""

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

if [[ -n "$repo_dir" ]]; then
  repo_dir="$(resolve_dir_path "$repo_dir")"
  source_repo="$repo_dir"
  source_label="local repo"
elif [[ -n "$repo_url" || -n "$repo_ref" || -z "$candidate_repo" || ! -d "$candidate_repo/plugins/e2e" ]]; then
  if [[ -z "$repo_url" ]]; then
    repo_url="$official_repo_url"
  fi
  if [[ -z "$repo_ref" && "$repo_url" == "$official_repo_url" ]]; then
    repo_ref="$default_remote_ref"
  fi

  command -v git >/dev/null 2>&1 || fail "git is required when installing from a remote repo"
  tmp_dir="$(mktemp -d)"
  clone_repo_at_ref "$repo_url" "$repo_ref" "$tmp_dir/repo"
  source_repo="$tmp_dir/repo"
  if [[ -n "$repo_ref" ]]; then
    source_label="remote repo ($repo_ref)"
  else
    source_label="remote repo"
  fi
else
  source_repo="$candidate_repo"
  source_label="local checkout"
fi

skill_src="$source_repo/plugins/e2e/skills/use-e2e"
[[ -d "$skill_src" ]] || fail_missing_skill_source "$skill_src"

[[ -d "$skill_src" ]] || fail "missing skill source: $skill_src"

# The e2ectl CLI is intentionally NOT installed here.
# The use-e2e skill prompts the user to choose global vs project-local
# install on first use and runs the correct npm command based on the answer.

if [[ "$target" == "codex" || "$target" == "all" ]]; then
  copy_dir "$skill_src" "$codex_home/skills/use-e2e"
fi

if [[ "$target" == "claude" || "$target" == "all" ]]; then
  copy_dir "$skill_src" "$claude_home/skills/use-e2e"
  install_claude_command "$claude_home/skills/use-e2e/SKILL.md" "$claude_home/commands/use-e2e.md"
fi

if [[ "$target" == "opencode" || "$target" == "all" ]]; then
  copy_dir "$skill_src" "$opencode_home/skills/use-e2e"
fi

if [[ "$target" == "amp" ]]; then
  install_amp "$skill_src"
fi

printf '\nDone.\n'
printf 'Codex skills path:  %s\n' "$codex_home/skills/use-e2e"
printf 'Claude skills path: %s\n' "$claude_home/skills/use-e2e"
printf 'OpenCode skills path: %s\n' "$opencode_home/skills/use-e2e"
if [[ "$target" == "amp" ]]; then
  printf 'Amp skill name:       %s\n' "use-e2e"
fi
