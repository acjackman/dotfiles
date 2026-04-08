#!/usr/bin/env bash
# wt-tmux-hook.sh - Pre-remove/merge hook: clean up tmux panes in the worktree
#
# Reads worktree_path and primary_worktree_path from stdin JSON (worktrunk hook context).
# Idle shell panes are killed; busy panes cause an error that aborts the operation.
# After cleanup, switches to the primary worktree's tmux session.

set -euo pipefail

IDLE_SHELLS="^(zsh|bash|fish|sh)$"

ctx=$(cat)
worktree_path=$(printf '%s' "$ctx" | jq -r '.worktree_path')
primary_worktree_path=$(printf '%s' "$ctx" | jq -r '.primary_worktree_path')

[[ -z "${TMUX:-}" ]] && exit 0

wt_path_real="$(cd "$worktree_path" && pwd -P)"

busy_panes=()
idle_panes=()

while IFS=$'\t' read -r pane_id pane_path pane_cmd session_name window_name pane_index; do
  [[ "$pane_id" == "$TMUX_PANE" ]] && continue
  pane_path_real="$(cd "$pane_path" 2>/dev/null && pwd -P)" || continue
  case "$pane_path_real" in
    "$wt_path_real"|"$wt_path_real"/*)
      if [[ "$pane_cmd" =~ $IDLE_SHELLS ]]; then
        idle_panes+=("$pane_id")
      else
        rel_path="${pane_path_real#"$wt_path_real"}"
        rel_path="${rel_path#/}"
        [[ -z "$rel_path" ]] && rel_path="."
        busy_panes+=("$pane_id	$session_name	$window_name	$pane_index	$pane_cmd	$rel_path")
      fi
      ;;
  esac
done < <(tmux list-panes -a -F "#{pane_id}	#{pane_current_path}	#{pane_current_command}	#{session_name}	#{window_name}	#{pane_index}")

if [[ ${#busy_panes[@]} -gt 0 ]]; then
  echo "error: busy panes in worktree directory:" >&2
  for entry in "${busy_panes[@]}"; do
    IFS=$'\t' read -r id sess win pane_idx cmd path <<< "$entry"
    echo "  [$sess:$win.$pane_idx] $cmd ($path)" >&2
    echo "    → tmux switch-client -t '$sess:$win.$pane_idx'" >&2
  done
  echo "Close these applications before proceeding." >&2
  exit 1
fi

if [[ ${#idle_panes[@]} -gt 0 ]]; then
  landing_session="$(tmux-session-name "$primary_worktree_path")"

  if ! tmux has-session -t "=$landing_session" 2>/dev/null; then
    tmux new-session -d -s "$landing_session" -c "$primary_worktree_path"
  fi

  tmux switch-client -t "=$landing_session"

  for pane_id in "${idle_panes[@]}"; do
    [[ "$pane_id" == "$TMUX_PANE" ]] && continue
    tmux kill-pane -t "$pane_id" 2>/dev/null || true
  done
fi
