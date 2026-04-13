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

target="all"
repo_url=""
repo_dir=""
codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
opencode_home="${OPENCODE_HOME:-$HOME/.config/opencode}"
official_repo_url="https://github.com/e2enetworks-oss/e2enetworks-skills.git"

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

# The e2ectl CLI is intentionally NOT installed here.
# The use-e2e skill prompts the user to choose global vs project-local
# install on first use and runs the correct npm command based on the answer.

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
printf 'Codex skills path:  %s\n' "$codex_home/skills/use-e2e"
printf 'Claude skills path: %s\n' "$claude_home/skills/use-e2e"
printf 'OpenCode skills path: %s\n' "$opencode_home/skills/use-e2e"
if [[ "$target" == "amp" ]]; then
  printf 'Amp skill name:    %s\n' "use-e2e"
fi
