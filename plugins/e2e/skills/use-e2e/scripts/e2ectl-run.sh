#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  e2ectl-run.sh [--bin <path>] [--cwd <dir>] [--env-file <file>] [--output <file>] [--print-command] -- <cli-args...>

Options:
  --bin             Binary or script to run (default: auto-detect e2ectl, then hitesh-test)
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

bin_path=""
bin_explicit="false"
cwd=""
env_file=""
output_file=""
print_command="false"
command_args=()

resolve_dir_path() {
  (
    cd "$1" >/dev/null 2>&1 || exit 1
    pwd -P
  )
}

resolve_file_path() {
  local target_path="$1"
  local target_dir=""

  target_dir="$(dirname "$target_path")"
  printf '%s/%s\n' "$(resolve_dir_path "$target_dir")" "$(basename "$target_path")"
}

resolve_named_bin() {
  local bin_name="$1"
  local search_cwd="${2:-}"
  local local_bin=""

  if command -v "$bin_name" >/dev/null 2>&1; then
    command -v "$bin_name"
    return 0
  fi

  if [[ -n "$search_cwd" ]]; then
    local_bin="$search_cwd/node_modules/.bin/$bin_name"
    if [[ -x "$local_bin" ]]; then
      printf '%s\n' "$local_bin"
      return 0
    fi
  fi

  return 1
}

resolve_default_bin() {
  local candidate=""
  local resolved_bin=""

  for candidate in e2ectl hitesh-test; do
    if resolved_bin="$(resolve_named_bin "$candidate" "$cwd")"; then
      printf '%s\n' "$resolved_bin"
      return 0
    fi
  done

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bin)
      bin_path="${2:-}"
      bin_explicit="true"
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
  cwd="$(resolve_dir_path "$cwd")"
fi

if [[ -n "$env_file" ]]; then
  [[ -f "$env_file" ]] || fail "--env-file does not exist: $env_file"
  env_file="$(resolve_file_path "$env_file")"
fi

if [[ "$bin_explicit" == "false" ]]; then
  if resolved_bin="$(resolve_default_bin)"; then
    bin_path="$resolved_bin"
  elif [[ -n "$cwd" ]]; then
    fail "binary not found: checked e2ectl and hitesh-test in PATH and $cwd/node_modules/.bin"
  else
    fail "binary not found in PATH: checked e2ectl and hitesh-test"
  fi
fi

if [[ "$bin_path" == */* ]]; then
  if [[ "$bin_path" != /* && -n "$cwd" ]]; then
    bin_path="$cwd/$bin_path"
  fi
  [[ -x "$bin_path" ]] || fail "--bin is not executable: $bin_path"
  bin_path="$(resolve_file_path "$bin_path")"
else
  if resolved_bin="$(resolve_named_bin "$bin_path" "$cwd")"; then
    bin_path="$resolved_bin"
  elif [[ -n "$cwd" ]]; then
    fail "binary not found: $bin_path (checked PATH and $cwd/node_modules/.bin)"
  else
    fail "binary not found in PATH: $bin_path"
  fi
fi

if [[ "$print_command" == "true" ]]; then
  printf 'Running: %s' "$bin_path" >&2
  for arg in "${command_args[@]}"; do
    printf ' %q' "$arg" >&2
  done
  printf '\n' >&2
fi

load_env_file() {
  local source_status=0

  [[ -n "$env_file" ]] || return 0

  set -a
  # shellcheck disable=SC1090
  . "$env_file" || source_status=$?
  set +a

  if [[ $source_status -ne 0 ]]; then
    printf 'Error: failed to load --env-file: %s\n' "$env_file" >&2
    return "$source_status"
  fi
}

runner() {
  if [[ -n "$cwd" ]]; then
    cd "$cwd" || return $?
  fi

  load_env_file || return $?

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
