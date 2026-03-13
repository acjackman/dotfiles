#!/usr/bin/env bash
# safe-fd: read-only fd wrapper that blocks --exec options
set -euo pipefail

for arg in "$@"; do
  case "$arg" in
    -x | --exec | -X | --exec-batch)
      echo "error: $arg is not allowed in safe-fd" >&2
      exit 1
      ;;
  esac
done

exec fd "$@"
