#!/usr/bin/env bash
set -euo pipefail
# Mark the current directory as trusted in Claude Code's config.
# Designed to run as a worktrunk post-switch hook where $PWD is the worktree.

claude_json="$HOME/.claude.json"
[[ ! -f "$claude_json" ]] && exit 0

path="$PWD"

if jq -e --arg p "$path" '.projects[$p].hasTrustDialogAccepted == true' "$claude_json" >/dev/null 2>&1; then
    exit 0
fi

tmp="${claude_json}.tmp.$$"
jq --arg p "$path" '.projects[$p] = (.projects[$p] // {}) + {"hasTrustDialogAccepted": true}' "$claude_json" > "$tmp" \
    && mv "$tmp" "$claude_json"
