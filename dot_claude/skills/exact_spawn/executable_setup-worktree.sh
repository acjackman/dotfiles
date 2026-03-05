#!/usr/bin/env bash
set -euo pipefail

# Create or reuse a worktree for a branch, printing its JSON entry from wt list.
# Creates a .tmp directory in the worktree for prompt files.
# Usage: setup-worktree.sh <branch-name> [--base <ref>] [--repo <path>]
#
# --repo <path>  Target a different git repo. If it's a bare repo managed by
#                worktrunk, worktrees are created there via `wt -C`. If it's a
#                regular checkout, no worktree is created — the agent runs
#                directly in that directory.

WT=/opt/homebrew/bin/wt

ensure_trust() {
    # Delegate to the shared worktrunk hook script.
    (cd "$1" && "$HOME/.config/worktrunk/hooks/ensure-claude-trust.sh")
}

usage() {
    echo "Usage: setup-worktree.sh <branch-name> [--base <ref>] [--repo <path>]" >&2
    exit 1
}

[[ $# -lt 1 ]] && usage

branch="$1"
shift

base=""
repo=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            [[ $# -lt 2 ]] && usage
            base="$2"
            shift 2
            ;;
        --repo)
            [[ $# -lt 2 ]] && usage
            repo="$(cd "$2" && pwd)"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Build the wt command — prefix with -C when targeting another repo
wt_cmd=("$WT")
[[ -n "$repo" ]] && wt_cmd+=(-C "$repo")

# When --repo is set, check if worktrunk manages it. If not, treat as a
# regular checkout and skip worktree creation entirely.
if [[ -n "$repo" ]] && ! "${wt_cmd[@]}" list --format=json &>/dev/null; then
    mkdir -p "$repo/.tmp"
    ensure_trust "$repo"
    current_branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "HEAD")
    printf '{"branch":"%s","path":"%s"}\n' "$current_branch" "$repo"
    exit 0
fi

existing=$("${wt_cmd[@]}" list --format=json | jq -e --arg b "$branch" '.[] | select(.branch == $b)' 2>/dev/null) || existing=""

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
    create_args=(switch --no-cd --create "$branch")
    [[ -n "$base" ]] && create_args+=(--base "$base")

    TMUX_PANE= "${wt_cmd[@]}" "${create_args[@]}" >&2

    result=$("${wt_cmd[@]}" list --format=json | jq -e --arg b "$branch" '.[] | select(.branch == $b)')
    worktree_path=$(echo "$result" | jq -r '.path')
    mkdir -p "$worktree_path/.tmp"
    ensure_trust "$worktree_path"
    echo "$result"
fi
