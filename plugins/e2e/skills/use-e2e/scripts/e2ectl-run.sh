#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  e2ectl-run.sh [--bin <path>] [--cwd <dir>] [--env-file <file>] [--output <file>] [--print-command] -- <cli-args...>

Options:
  --bin             Binary or script to run
  --cwd             Working directory to run in
  --env-file        Shell-compatible env file to source before running
  --output          File to write combined stdout/stderr to
  --print-command   Print the resolved command before execution
  -h, --help        Show this help

Examples:
  ./e2ectl-run.sh -- --help
  ./e2ectl-run.sh --cwd /workspace/app -- config list
  ./e2ectl-run.sh --cwd /workspace/app --output .artifacts/run.log -- test smoke
  ./e2ectl-run.sh --bin ./bin/e2ectl --env-file .env.local -- status
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

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

  if command -v "$bin_name" >/dev/null 2>&1; then
    command -v "$bin_name"
    return 0
  fi

  return 1
}

resolve_repo_checkout_bin() {
  local search_cwd="$1"
  local package_json="$search_cwd/package.json"

  [[ -f "$package_json" ]] || return 1
  grep -Eq '"name"[[:space:]]*:[[:space:]]*"(@e2enetworks-oss/e2ectl|e2ectl)"' "$package_json" || return 1
  [[ -f "$search_cwd/dist/app/index.js" ]] || return 1

  printf '%s\n' "$search_cwd/dist/app/index.js"
  return 0
}

mode="${E2E_SKILLS_MODE:-public}"
bin_path=""
bin_explicit="false"
cwd=""
env_file=""
output_file=""
print_command="false"
command_args=()

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

[[ "$mode" == "public" || "$mode" == "internal" ]] || fail "invalid E2E_SKILLS_MODE: $mode"
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
  if [[ "$mode" == "internal" && -n "$cwd" ]]; then
    if resolved_bin="$(resolve_repo_checkout_bin "$cwd")"; then
      bin_path="$resolved_bin"
    fi
  fi

  if [[ -z "$bin_path" ]]; then
    if resolved_bin="$(resolve_named_bin e2ectl)"; then
      bin_path="$resolved_bin"
    elif [[ "$mode" == "public" ]]; then
      fail "e2ectl was not found. Rerun the installer to install or update it, or pass --bin to use a custom path."
    elif [[ -n "$cwd" ]]; then
      fail "e2ectl was not found. Checked $cwd/dist/app/index.js and PATH. Rerun the installer or pass --bin to use a custom path."
    else
      fail "e2ectl was not found in PATH. Rerun the installer or pass --bin to use a custom path."
    fi
  fi
fi

if [[ "$bin_path" == */* ]]; then
  if [[ "$bin_path" != /* && -n "$cwd" ]]; then
    bin_path="$cwd/$bin_path"
  fi
  if [[ "$bin_path" == *.js ]]; then
    [[ -f "$bin_path" ]] || fail "--bin JavaScript entrypoint does not exist: $bin_path"
  else
    [[ -x "$bin_path" ]] || fail "--bin is not executable: $bin_path"
  fi
  bin_path="$(resolve_file_path "$bin_path")"
else
  if resolved_bin="$(resolve_named_bin "$bin_path")"; then
    bin_path="$resolved_bin"
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

  if [[ "$bin_path" == *.js ]]; then
    node "$bin_path" "${command_args[@]}"
    return $?
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
