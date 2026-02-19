#!/usr/bin/env bash
set -euo pipefail

# Launch an interactive Claude session with an initial prompt from a file.
# Usage: launch.sh [--permission-mode <mode>] <prompt-file>

permission_mode="acceptEdits"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --permission-mode) permission_mode="$2"; shift 2 ;;
        *) break ;;
    esac
done

if [[ $# -lt 1 ]] || [[ ! -f "$1" ]]; then
    echo "Usage: launch.sh [--permission-mode <mode>] <prompt-file>"
    exit 1
fi

prompt="$(cat "$1")"
exec claude --permission-mode "$permission_mode" "$prompt"
