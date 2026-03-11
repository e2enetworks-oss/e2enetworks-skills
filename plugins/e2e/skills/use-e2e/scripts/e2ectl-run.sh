#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  e2ectl-run.sh [--bin <path>] [--cwd <dir>] [--env-file <file>] [--output <file>] [--print-command] -- <e2ectl-args...>

Options:
  --bin             Binary or script to run (default: e2ectl)
  --cwd             Working directory to run in
  --env-file        Shell-compatible env file to source before running
  --output          File to write combined stdout/stderr to
  --print-command   Print the resolved command before execution
  -h, --help        Show this help

Examples:
  ./e2ectl-run.sh -- --help
  ./e2ectl-run.sh --cwd /workspace/app --output .artifacts/run.log -- test smoke
  ./e2ectl-run.sh --bin ./bin/e2ectl --env-file .env.local -- status
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

bin_path="e2ectl"
cwd=""
env_file=""
output_file=""
print_command="false"
command_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bin)
      bin_path="${2:-}"
      shift 2
      ;;
    --cwd)
      cwd="${2:-}"
      shift 2
      ;;
    --env-file)
      env_file="${2:-}"
      shift 2
      ;;
    --output)
      output_file="${2:-}"
      shift 2
      ;;
    --print-command)
      print_command="true"
      shift
      ;;
    --)
      shift
      command_args=("$@")
      break
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

[[ ${#command_args[@]} -gt 0 ]] || fail "missing command arguments; pass them after --"

if [[ -n "$cwd" ]]; then
  [[ -d "$cwd" ]] || fail "--cwd does not exist: $cwd"
fi

if [[ -n "$env_file" ]]; then
  [[ -f "$env_file" ]] || fail "--env-file does not exist: $env_file"
fi

if [[ "$bin_path" == */* ]]; then
  [[ -x "$bin_path" ]] || fail "--bin is not executable: $bin_path"
else
  command -v "$bin_path" >/dev/null 2>&1 || fail "binary not found in PATH: $bin_path"
fi

if [[ "$print_command" == "true" ]]; then
  printf 'Running: %s' "$bin_path" >&2
  for arg in "${command_args[@]}"; do
    printf ' %q' "$arg" >&2
  done
  printf '\n' >&2
fi

runner() {
  if [[ -n "$cwd" ]]; then
    cd "$cwd"
  fi

  if [[ -n "$env_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    . "$env_file"
    set +a
  fi

  "$bin_path" "${command_args[@]}"
}

set +e
output="$(runner 2>&1)"
status=$?
set -e

if [[ -n "$output_file" ]]; then
  mkdir -p "$(dirname "$output_file")"
  printf '%s\n' "$output" > "$output_file"
fi

printf '%s\n' "$output"
exit "$status"
