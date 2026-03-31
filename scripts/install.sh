#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Install e2enetworks-skills into Codex, Claude Code, OpenCode, or Amp.
This script installs the skill pack only. It does not install the e2ectl CLI.

Usage:
  install.sh [--target codex|claude|claude-code|opencode|open-code|amp|all] [--scope global|project] [--project-dir <path>] [--repo-url <git-url>] [--repo-dir <path>] [--codex-home <path>] [--claude-home <path>] [--opencode-home <path>] [--force]

Options:
  --target      Install target (default: all)
  --scope       Install scope. If omitted in an interactive terminal, ask global vs project.
  --project-dir Project root for --scope project (default: current working directory)
  --repo-url    Git URL to clone when script runs via curl pipe (default: official repo)
  --repo-dir    Local repo directory containing plugins/e2e
  --codex-home  Codex home (default: $CODEX_HOME or ~/.codex)
  --claude-home Claude home (default: $CLAUDE_HOME or ~/.claude)
  --opencode-home OpenCode config dir (default: $OPENCODE_HOME or ~/.config/opencode)
  --force       Overwrite existing installs
  -h, --help    Show this help

Examples:
  ./scripts/install.sh --force
  ./scripts/install.sh --scope project --project-dir "$PWD" --force
  ./scripts/install.sh --target amp --force
  curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
    bash -s -- --target claude --force
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

target="all"
scope=""
repo_url=""
repo_dir=""
project_dir="$PWD"
codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
opencode_home="${OPENCODE_HOME:-$HOME/.config/opencode}"
force="false"
official_repo_url="https://github.com/e2enetworks-oss/e2enetworks-skills.git"

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
    --repo-dir)
      repo_dir="${2:-}"
      shift 2
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

copy_dir() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" ]]; then
    if [[ "$force" == "true" ]]; then
      rm -rf "$dst"
    elif prompt_yes_no "Existing install found at $dst. Update it now? [y/N] " "n"; then
      rm -rf "$dst"
    else
      printf 'Skip existing path (use --force to overwrite): %s\n' "$dst"
      return 0
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

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
candidate_repo="$(cd -- "$script_dir/.." && pwd)"
source_repo=""
tmp_dir=""

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

if [[ -z "$scope" ]]; then
  if ! scope="$(prompt_choice "Install skills globally or in this project? [global/project] (default: global): " "global")"; then
    fail "install scope was not provided and no interactive terminal was available. Pass --scope global or --scope project."
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
  source_repo="$repo_dir"
elif [[ -d "$candidate_repo/plugins/e2e" ]]; then
  source_repo="$candidate_repo"
else
  if [[ -z "$repo_url" ]]; then
    repo_url="$official_repo_url"
  fi

  command -v git >/dev/null 2>&1 || fail "git is required when using --repo-url"
  tmp_dir="$(mktemp -d)"
  git clone --depth 1 "$repo_url" "$tmp_dir/repo" >/dev/null
  source_repo="$tmp_dir/repo"
fi

skill_src="$source_repo/plugins/e2e/skills/use-e2e"

[[ -d "$skill_src" ]] || fail "missing skill source: $skill_src"

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
printf 'Install scope:      %s\n' "$scope"
if [[ "$scope" == "project" ]]; then
  printf 'Project root:       %s\n' "$project_dir"
fi
printf 'Codex skills path:  %s\n' "$codex_home/skills/use-e2e"
printf 'Claude skills path: %s\n' "$claude_home/skills/use-e2e"
printf 'OpenCode skills path: %s\n' "$opencode_home/skills/use-e2e"
if [[ "$target" == "amp" ]]; then
  printf 'Amp skill name:    %s\n' "use-e2e"
fi
