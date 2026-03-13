#!/usr/bin/env bash
# safe-fd: read-only fd wrapper that blocks --exec options
set -euo pipefail

fd_args=()
grep_args=()
found_grep=false

for arg in "$@"; do
  if [[ "$found_grep" == true ]]; then
    grep_args+=("$arg")
  elif [[ "$arg" == "--grep" ]]; then
    found_grep=true
  else
    case "$arg" in
      -x | --exec | -X | --exec-batch)
        echo "error: $arg is not allowed in safe-fd" >&2
        exit 1
        ;;
    esac
    fd_args+=("$arg")
  fi
done

if [[ "$found_grep" == true ]]; then
  fd "${fd_args[@]}" | xargs bash ~/.claude/skills/safe-rg/safe-rg.sh "${grep_args[@]}"
else
  exec fd "${fd_args[@]}"
fi
