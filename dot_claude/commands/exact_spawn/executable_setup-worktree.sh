#!/usr/bin/env bash
set -euo pipefail

# Create or reuse a worktree for a branch, printing its JSON entry from wt list.
# Creates a .tmp directory in the worktree for prompt files.
# Usage: setup-worktree.sh <branch-name> [--base <ref>]

WT=/opt/homebrew/bin/wt

ensure_trust() {
    local path="$1"
    local claude_json="$HOME/.claude/.claude.json"
    [[ ! -f "$claude_json" ]] && return

    if jq -e --arg p "$path" '.projects[$p].hasTrustDialogAccepted == true' "$claude_json" >/dev/null 2>&1; then
        return
    fi

    local tmp="${claude_json}.tmp.$$"
    jq --arg p "$path" '.projects[$p] = (.projects[$p] // {}) + {"hasTrustDialogAccepted": true}' "$claude_json" > "$tmp" \
        && mv "$tmp" "$claude_json"
}

usage() {
    echo "Usage: setup-worktree.sh <branch-name> [--base <ref>]" >&2
    exit 1
}

[[ $# -lt 1 ]] && usage

branch="$1"
shift

base=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            [[ $# -lt 2 ]] && usage
            base="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

existing=$("$WT" list --format=json | jq -e --arg b "$branch" '.[] | select(.branch == $b)' 2>/dev/null) || existing=""

if [[ -n "$existing" ]]; then
    worktree_path=$(echo "$existing" | jq -r '.path')

    if [[ -n "$base" ]]; then
        head_commit=$(git -C "$worktree_path" rev-parse HEAD)
        base_commit=$(git rev-parse "$base")

        if [[ "$head_commit" != "$base_commit" ]] && ! git merge-base --is-ancestor "$head_commit" "$base_commit"; then
            echo "Error: existing worktree for '$branch' at $worktree_path is not compatible with --base $base" >&2
            echo "  worktree HEAD: $head_commit" >&2
            echo "  base ref:      $base_commit ($base)" >&2
            echo "  HEAD is not an ancestor of base; cannot fast-forward." >&2
            exit 1
        fi
    fi

    mkdir -p "$worktree_path/.tmp"
    ensure_trust "$worktree_path"
    echo "$existing"
else
    create_args=(switch --create "$branch")
    [[ -n "$base" ]] && create_args+=(--base "$base")

    "$WT" "${create_args[@]}" >&2

    result=$("$WT" list --format=json | jq -e --arg b "$branch" '.[] | select(.branch == $b)')
    worktree_path=$(echo "$result" | jq -r '.path')
    mkdir -p "$worktree_path/.tmp"
    ensure_trust "$worktree_path"
    echo "$result"
fi
