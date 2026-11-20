#!/usr/bin/env bash
# wt-rex-hook.sh - Pre-remove/merge hook: clean up Rex panes in the worktree
#
# Rex counterpart to wt-herdr-hook.sh / wt-tmux-hook.sh.
# Usage: wt-rex-hook.sh <worktree_path> (passed as a {{ worktree_path }} template arg).
# Idle shell panes (blocks) are closed; busy ones (any non-shell foreground
# process, e.g. an agent) cause an error that aborts the operation.
# The pane that ran `wt remove` is left alone: worktrunk's shell integration cds it
# to the primary worktree itself.

set -euo pipefail

IDLE_SHELLS="^-?(zsh|bash|fish|sh)$"

worktree_path=${1:?usage: wt-rex-hook.sh <worktree_path>}

PATH="$HOME/.local/bin:$PATH"
rex --help >/dev/null 2>&1 || exit 0
# --autostart=false: no Rex server means no panes to clean up; don't start one.
sessions=$(rex --autostart=false ls --json 2>/dev/null | jq -r '.sessions[].session_id') || exit 0

wt_path_real="$(cd "$worktree_path" && pwd -P)"

# Our own block, but only if the server agrees it exists: $REX_BLOCK is an
# ordinary env var and can be inherited from another pane.
self_block=$(rex whoami --json 2>/dev/null | jq -r '.block_id // empty') || self_block=""

block_call() { # block_call <session> <block> <method>
  rex api call block.method -- "$(jq -cn --arg s "$1" --arg b "$2" --arg m "$3" \
    '{session_id: $s, block_id: $b, method: $m}')" 2>/dev/null
}

busy=()
idle=() # "session<TAB>block"

for s in $sessions; do
  label=$(rex ls --json | jq -r --arg s "$s" '.sessions[] | select(.session_id == $s) | .label')
  blocks=$(rex api call session.list_blocks -- "$(jq -cn --arg s "$s" '{session_id: $s}')" 2>/dev/null |
    jq -r '.blocks[] | select(.creator_name == "com.superlogical.terminal") | .block_id') || continue

  for b in $blocks; do
    [[ -n "$self_block" && "$b" == "$self_block" ]] && continue
    proc=$(block_call "$s" "$b" process) || continue
    cwd=$(jq -r '.foreground.cwd // empty' <<<"$proc")
    [[ -n "$cwd" ]] || continue
    cwd_real="$(cd "$cwd" 2>/dev/null && pwd -P)" || continue
    case "$cwd_real" in
      "$wt_path_real"|"$wt_path_real"/*) ;;
      *) continue ;;
    esac

    rel_path="${cwd_real#"$wt_path_real"}"
    rel_path="${rel_path#/}"
    fg=$(jq -r '.foreground.argv0 // .foreground.name // "unknown"' <<<"$proc")
    fg="${fg##*/}"
    if [[ "$fg" =~ $IDLE_SHELLS ]]; then
      idle+=("$s	$b")
    else
      busy+=("$s	$b	${label:-$s}	$fg	${rel_path:-.}")
    fi
  done
done

if [[ ${#busy[@]} -gt 0 ]]; then
  echo "error: busy Rex panes in worktree directory:" >&2
  for entry in "${busy[@]}"; do
    IFS=$'\t' read -r s b label cmd path <<<"$entry"
    echo "  [$label ${b##*-}] $cmd ($path)" >&2
    echo "    → rex focus -s '$s' '$b'" >&2
  done
  echo "Close these agents/applications before proceeding." >&2
  exit 1
fi

touched=()
for entry in ${idle[@]+"${idle[@]}"}; do
  IFS=$'\t' read -r s b <<<"$entry"
  rex api call block.close -- "$(jq -cn --arg s "$s" --arg b "$b" '{session_id: $s, block_id: $b}')" \
    >/dev/null 2>&1 || true
  touched+=("$s")
done

# Rex keeps a session alive with no blocks in it; drop the ones we emptied.
for s in $(printf '%s\n' ${touched[@]+"${touched[@]}"} | sort -u); do
  left=$(rex api call session.list_blocks -- "$(jq -cn --arg s "$s" '{session_id: $s}')" 2>/dev/null |
    jq '.blocks | length') || continue
  [[ "$left" == 0 ]] && rex kill "$s" >/dev/null 2>&1 || true
done
