#!/usr/bin/env bash
set -euo pipefail

# Install e2enetworks-skills (use-e2e) into Codex, Claude Code, OpenCode, or Amp.
# The e2ectl CLI is installed on first use of the skill, not here.
#
# Usage:
#   ./scripts/install.sh [target]
#   curl -fsSL https://raw.githubusercontent.com/e2enetworks-oss/e2enetworks-skills/main/scripts/install.sh | bash
#
# target: codex | claude | claude-code | opencode | open-code | amp | all (default: all)
# env overrides: CODEX_HOME, CLAUDE_HOME, OPENCODE_HOME, REPO_URL, REPO_REF

target="${1:-all}"
codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
opencode_home="${OPENCODE_HOME:-$HOME/.config/opencode}"
repo_url="${REPO_URL:-https://github.com/e2enetworks-oss/e2enetworks-skills.git}"
repo_ref="${REPO_REF:-main}"

case "$target" in claude-code) target=claude ;; open-code) target=opencode ;; esac
case "$target" in
  codex|claude|opencode|amp|all) ;;
  -h|--help)
    sed -n '3,13p' "$0"
    exit 0
    ;;
  *) echo "bad target: $target (use codex|claude|opencode|amp|all)" >&2; exit 1 ;;
esac

# Resolve skill source: local checkout if available, otherwise clone.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ -n "$script_dir" && -d "$script_dir/../plugins/e2e" ]]; then
  src="$(cd "$script_dir/.." && pwd)/plugins/e2e/skills/use-e2e"
else
  command -v git >/dev/null || { echo "git required to clone $repo_url" >&2; exit 1; }
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  git clone --depth 1 --branch "$repo_ref" "$repo_url" "$tmp/repo" >/dev/null
  src="$tmp/repo/plugins/e2e/skills/use-e2e"
fi
[[ -d "$src" ]] || { echo "missing skill source: $src" >&2; exit 1; }

install_dir() {
  rm -rf "$1"
  mkdir -p "$(dirname "$1")"
  cp -R "$src" "$1"
  echo "Installed: $1"
}

[[ "$target" == codex    || "$target" == all ]] && install_dir "$codex_home/skills/use-e2e"
[[ "$target" == claude   || "$target" == all ]] && install_dir "$claude_home/skills/use-e2e"
[[ "$target" == opencode || "$target" == all ]] && install_dir "$opencode_home/skills/use-e2e"
if [[ "$target" == amp ]]; then
  command -v amp >/dev/null || { echo "amp CLI required for --target amp" >&2; exit 1; }
  amp skill add "$src" --global --name use-e2e --overwrite
  echo "Installed: amp skill use-e2e"
fi

echo
echo "Done."
[[ "$target" == codex    || "$target" == all ]] && echo "Codex:    $codex_home/skills/use-e2e" || :
[[ "$target" == claude   || "$target" == all ]] && echo "Claude:   $claude_home/skills/use-e2e" || :
[[ "$target" == opencode || "$target" == all ]] && echo "OpenCode: $opencode_home/skills/use-e2e" || :
[[ "$target" == amp ]] && echo "Amp skill: use-e2e" || :
