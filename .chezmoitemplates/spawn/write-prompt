#!/usr/bin/env bash
set -euo pipefail
# Usage: write-prompt.sh <worktree-path> <<'PROMPT'
#        ... task description ...
#        PROMPT
# Writes stdin to the worktree's .tmp/ dir with a datestamp name.
# Prints the destination path.

[[ $# -ne 1 ]] && { echo "Usage: write-prompt.sh <worktree-path>" >&2; exit 1; }

worktree="$1"
stamp=$(date +%Y-%m-%d-%H%M%S)
dest="$worktree/.tmp/prompt-$stamp.md"

mkdir -p "$worktree/.tmp"
cat > "$dest"
echo "$dest"
