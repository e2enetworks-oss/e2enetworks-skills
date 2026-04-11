#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Install e2enetworks-skills into Codex, Claude Code, OpenCode, or Amp.
This script installs the skill pack and manages the global e2ectl CLI.
Run it again later to update the installed skill.

Usage:
  install.sh [--target codex|claude|claude-code|opencode|open-code|amp|all] [--scope global|project] [--project-dir <path>] [--repo-url <git-url>] [--repo-ref <branch|tag|commit>] [--repo-dir <path>] [--skip-cli] [--upgrade-cli] [--codex-home <path>] [--claude-home <path>] [--opencode-home <path>] [--force]

Options:
  --target        Install target (default: all)
  --scope         Install scope. Defaults to global outside interactive terminals.
  --project-dir   Project root for --scope project (default: current working directory)
  --repo-url      Git URL to clone when installing from a remote repo (default: official repo)
  --repo-ref      Remote branch, tag, or commit to install from (default remote ref: main)
  --repo-dir      Local repo directory containing plugins/e2e
  --skip-cli      Skip e2ectl installation and upgrade checks
  --upgrade-cli   Upgrade the globally installed e2ectl to the latest stable release
  --codex-home    Codex home (default: $CODEX_HOME or ~/.codex)
  --claude-home   Claude home (default: $CLAUDE_HOME or ~/.claude)
  --opencode-home OpenCode config dir (default: $OPENCODE_HOME or ~/.config/opencode)
  --force         Replace existing installs without prompting
  -h, --help      Show this help

Examples:
  ./scripts/install.sh --force
  ./scripts/install.sh --scope project --project-dir "$PWD" --force
  ./scripts/install.sh --upgrade-cli --force
  ./scripts/install.sh --repo-ref intial-setup --target claude --force
  curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
    bash -s -- --target claude --force
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

warn() {
  printf 'Warning: %s\n' "$1" >&2
}

resolve_dir_path() {
  (
    cd "$1" >/dev/null 2>&1 || exit 1
    pwd -P
  )
}

prompt_choice() {
  local prompt_text="$1"
  local default_value="$2"
  local response=""

  if [[ ! -t 0 || ! -t 1 ]]; then
    return 1
  fi

  printf '%s' "$prompt_text" >&2
  IFS= read -r response || true
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

  if [[ ! -t 0 || ! -t 1 ]]; then
    return 1
  fi

  printf '%s' "$prompt_text" >&2
  IFS= read -r response || true
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

verify_active_cli() {
  local action_label="$1"
  local expected_version="${2:-}"
  local resolved_path=""
  local expected_path=""
  local active_version=""

  if ! resolved_path="$(resolve_installed_cli_path)"; then
    fail "$action_label completed, but e2ectl is still not available on PATH. This usually means npm installed it under a different global prefix."
  fi

  expected_path="$(resolve_expected_global_cli_path 2>/dev/null || true)"
  if [[ -n "$expected_path" && "$resolved_path" != "$expected_path" ]]; then
    fail "$action_label completed, but PATH still resolves e2ectl to $resolved_path instead of $expected_path. This usually means npm updated a different global prefix. Fix your PATH or switch to the correct Node/npm environment, then rerun the installer."
  fi

  if ! active_version="$(read_installed_cli_version)"; then
    fail "$action_label completed, but the active e2ectl at $resolved_path did not report a usable version."
  fi

  if [[ -n "$expected_version" ]] && version_is_less_than "$active_version" "$expected_version"; then
    fail "$action_label completed, but the active e2ectl on PATH is still $active_version at $resolved_path. This usually means npm updated a different global prefix. Fix your PATH or switch to the correct Node/npm environment, then rerun the installer."
  fi

  printf '%s\n' "$active_version"
}

ensure_cli_ready() {
  local cli_present="false"
  local installed_version=""
  local latest_version=""
  local verified_version=""
  local expected_version=""

  if [[ "$skip_cli" == "true" ]]; then
    cli_status="skipped (--skip-cli)"
    return 0
  fi

  if command -v e2ectl >/dev/null 2>&1; then
    cli_present="true"
  fi

  if [[ "$upgrade_cli" == "true" ]]; then
    command -v npm >/dev/null 2>&1 || fail "npm is required to upgrade @e2enetworks-oss/e2ectl. Install npm or rerun with --skip-cli."
    expected_version="$(fetch_latest_cli_version 2>/dev/null || true)"
    install_global_cli >/dev/null || fail "failed to upgrade @e2enetworks-oss/e2ectl globally"
    verified_version="$(verify_active_cli "global e2ectl upgrade" "$expected_version")"
    cli_status="upgraded globally ($verified_version)"
    return 0
  fi

  if [[ "$cli_present" == "false" ]]; then
    command -v npm >/dev/null 2>&1 || fail "npm is required to install @e2enetworks-oss/e2ectl globally. Install npm or rerun with --skip-cli."
    expected_version="$(fetch_latest_cli_version 2>/dev/null || true)"
    install_global_cli >/dev/null || fail "failed to install @e2enetworks-oss/e2ectl globally"
    verified_version="$(verify_active_cli "global e2ectl install" "$expected_version")"
    cli_status="installed globally ($verified_version)"
    return 0
  fi

  cli_status="kept existing install"

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
    cli_status="kept existing install ($installed_version)"
    return 0
  fi

  if [[ -t 0 && -t 1 ]]; then
    if prompt_yes_no "A newer stable e2ectl is available ($installed_version -> $latest_version). Upgrade it now? [Y/n] " "y"; then
      install_global_cli >/dev/null || fail "failed to upgrade @e2enetworks-oss/e2ectl globally"
      verified_version="$(verify_active_cli "global e2ectl upgrade" "$latest_version")"
      cli_status="upgraded globally ($installed_version -> $verified_version)"
    else
      cli_status="kept existing install ($installed_version)"
    fi
    return 0
  fi

  printf 'A newer stable e2ectl is available (%s -> %s). Rerun the installer interactively or pass --upgrade-cli to upgrade it.\n' "$installed_version" "$latest_version"
  return 0
}

target="all"
scope=""
repo_url=""
repo_ref=""
repo_dir=""
skip_cli="false"
upgrade_cli="false"
project_dir="$PWD"
codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
opencode_home="${OPENCODE_HOME:-$HOME/.config/opencode}"
force="false"
official_repo_url="https://github.com/e2enetworks-oss/e2enetworks-skills.git"
default_remote_ref="main"
cli_status="not checked"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      target="${2:-}"
      shift 2
      ;;
    --scope)
      scope="${2:-}"
      shift 2
      ;;
    --project-dir)
      project_dir="${2:-}"
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
    --force)
      force="true"
      shift
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

case "$scope" in
  ""|global|project) ;;
  *) fail "--scope must be one of: global, project" ;;
esac

[[ -z "$repo_dir" || -z "$repo_url" ]] || fail "--repo-dir cannot be combined with --repo-url"
[[ -z "$repo_dir" || -z "$repo_ref" ]] || fail "--repo-dir cannot be combined with --repo-ref"
[[ "$skip_cli" == "false" || "$upgrade_cli" == "false" ]] || fail "--skip-cli cannot be combined with --upgrade-cli"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
candidate_repo="$(cd -- "$script_dir/.." && pwd)"
source_repo=""
source_label=""
tmp_dir=""

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

if [[ -z "$scope" ]]; then
  if scope="$(prompt_choice "Install skills globally or in this project? [global/project] (default: global): " "global")"; then
    :
  else
    scope="global"
  fi
fi

case "$scope" in
  g|G|global|GLOBAL|Global)
    scope="global"
    ;;
  p|P|project|PROJECT|Project)
    scope="project"
    ;;
  *)
    fail "invalid scope choice: $scope"
    ;;
esac

if [[ "$scope" == "project" ]]; then
  [[ "$target" != "amp" ]] || fail "--scope project is not supported for target amp"
  mkdir -p "$project_dir"
  project_dir="$(resolve_dir_path "$project_dir")"
  codex_home="$project_dir/.codex"
  claude_home="$project_dir/.claude"
  opencode_home="$project_dir/.opencode"
fi

if [[ -n "$repo_dir" ]]; then
  repo_dir="$(resolve_dir_path "$repo_dir")"
  source_repo="$repo_dir"
  source_label="local repo"
elif [[ -n "$repo_url" || -n "$repo_ref" || ! -d "$candidate_repo/plugins/e2e" ]]; then
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
[[ -d "$skill_src" ]] || fail "missing skill source: $skill_src"

ensure_cli_ready

if [[ "$target" == "codex" || "$target" == "all" ]]; then
  copy_dir "$skill_src" "$codex_home/skills/use-e2e"
fi

if [[ "$target" == "claude" || "$target" == "all" ]]; then
  copy_dir "$skill_src" "$claude_home/skills/use-e2e"
fi

if [[ "$target" == "opencode" || "$target" == "all" ]]; then
  copy_dir "$skill_src" "$opencode_home/skills/use-e2e"
fi

if [[ "$target" == "amp" ]]; then
  install_amp "$skill_src"
fi

printf '\nDone.\n'
printf 'Install scope:        %s\n' "$scope"
printf 'Skill source:         %s\n' "$source_label"
printf 'e2ectl status:        %s\n' "$cli_status"
if [[ "$scope" == "project" ]]; then
  printf 'Project root:         %s\n' "$project_dir"
fi
printf 'Codex skills path:    %s\n' "$codex_home/skills/use-e2e"
printf 'Claude skills path:   %s\n' "$claude_home/skills/use-e2e"
printf 'OpenCode skills path: %s\n' "$opencode_home/skills/use-e2e"
if [[ "$target" == "amp" ]]; then
  printf 'Amp skill name:       %s\n' "use-e2e"
fi
