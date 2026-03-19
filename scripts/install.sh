#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Install e2enetworks-skills into Codex, Claude, and/or OpenCode directories.
This script installs the skill pack only. It does not install the e2ectl CLI.

Usage:
  install.sh [--target codex|claude|opencode|all] [--repo-url <git-url>] [--repo-dir <path>] [--codex-home <path>] [--claude-home <path>] [--opencode-home <path>] [--force]

Options:
  --target      Install target (default: all)
  --repo-url    Git URL to clone when script runs via curl pipe
  --repo-dir    Local repo directory containing plugins/e2e
  --codex-home  Codex home (default: $CODEX_HOME or ~/.codex)
  --claude-home Claude home (default: $CLAUDE_HOME or ~/.claude)
  --opencode-home OpenCode config dir (default: $OPENCODE_HOME or ~/.config/opencode)
  --force       Overwrite existing installs
  -h, --help    Show this help

Examples:
  ./scripts/install.sh --target all
  curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | \
    bash -s -- --repo-url https://github.com/e2enetworks-oss/e2enetworks-skills.git --target opencode
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
force="false"

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
  codex|claude|opencode|all) ;;
  *) fail "--target must be one of: codex, claude, opencode, all" ;;
esac

copy_dir() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" ]]; then
    if [[ "$force" == "true" ]]; then
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
elif [[ -n "$repo_url" ]]; then
  command -v git >/dev/null 2>&1 || fail "git is required when using --repo-url"
  tmp_dir="$(mktemp -d)"
  git clone --depth 1 "$repo_url" "$tmp_dir/repo" >/dev/null
  source_repo="$tmp_dir/repo"
else
  fail "cannot locate repo files. pass --repo-dir or --repo-url."
fi

skill_src="$source_repo/plugins/e2e/skills/use-e2e"
plugin_src="$source_repo/plugins/e2e"

[[ -d "$skill_src" ]] || fail "missing skill source: $skill_src"
[[ -d "$plugin_src" ]] || fail "missing plugin source: $plugin_src"

if [[ "$target" == "codex" || "$target" == "all" ]]; then
  copy_dir "$skill_src" "$codex_home/skills/use-e2e"
fi

if [[ "$target" == "claude" || "$target" == "all" ]]; then
  copy_dir "$plugin_src" "$claude_home/plugins/e2e"
fi

if [[ "$target" == "opencode" || "$target" == "all" ]]; then
  copy_dir "$skill_src" "$opencode_home/skills/use-e2e"
fi

printf '\nDone.\n'
printf 'Codex skills path:  %s\n' "$codex_home/skills/use-e2e"
printf 'Claude plugin path: %s\n' "$claude_home/plugins/e2e"
printf 'OpenCode skills path: %s\n' "$opencode_home/skills/use-e2e"
