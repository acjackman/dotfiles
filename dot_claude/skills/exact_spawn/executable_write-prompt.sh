#!/usr/bin/env bash
set -euo pipefail
# Usage: write-prompt.sh <source-file> <worktree-path>
# Moves a prompt file to the worktree's .tmp/ dir with a datestamp name.
# Prints the destination path.

[[ $# -ne 2 ]] && { echo "Usage: write-prompt.sh <source-file> <worktree-path>" >&2; exit 1; }

src="$1"
worktree="$2"
stamp=$(date +%Y-%m-%d-%H%M%S)
dest="$worktree/.tmp/prompt-$stamp.md"

mkdir -p "$worktree/.tmp"
mv "$src" "$dest"
echo "$dest"
