#!/usr/bin/env bash
set -euo pipefail

# Launch an interactive Claude session with an initial prompt from a file.
# Usage: launch.sh <prompt-file>

if [[ $# -lt 1 ]] || [[ ! -f "$1" ]]; then
    echo "Usage: launch.sh <prompt-file>"
    exit 1
fi

prompt="$(cat "$1")"
exec claude "$prompt"
