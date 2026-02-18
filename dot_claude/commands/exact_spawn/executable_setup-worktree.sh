#!/usr/bin/env bash
set -euo pipefail

# Create or reuse a worktree for a branch, printing its JSON entry from wt list.
# Usage: setup-worktree.sh <branch-name> [--base <ref>]

WT=/opt/homebrew/bin/wt

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

    echo "$existing"
else
    create_args=(switch --create "$branch")
    [[ -n "$base" ]] && create_args+=(--base "$base")

    "$WT" "${create_args[@]}" >&2

    "$WT" list --format=json | jq -e --arg b "$branch" '.[] | select(.branch == $b)'
fi
