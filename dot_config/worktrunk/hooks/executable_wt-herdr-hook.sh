#!/usr/bin/env bash
# wt-herdr-hook.sh - Pre-remove/merge hook: clean up herdr panes in the worktree
#
# Herdr counterpart to wt-tmux-hook.sh.
# Reads worktree_path and primary_worktree_path from stdin JSON (worktrunk hook context).
# Idle shell panes are closed; busy panes (an attached agent, or any non-shell
# foreground process) cause an error that aborts the operation.
# If this pane lives in the worktree, focus the primary worktree's workspace afterwards.

set -euo pipefail

IDLE_SHELLS="^-?(zsh|bash|fish|sh)$"

ctx=$(cat)
worktree_path=$(printf '%s' "$ctx" | jq -r '.worktree_path')
primary_worktree_path=$(printf '%s' "$ctx" | jq -r '.primary_worktree_path')

command -v herdr >/dev/null 2>&1 || exit 0
[[ -S "${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}" ]] || exit 0

panes_json=$(herdr pane list 2>/dev/null) || exit 0

wt_path_real="$(cd "$worktree_path" && pwd -P)"

# pane_id \t cwd \t agent \t workspace_id \t tab_id
pane_rows=$(printf '%s' "$panes_json" | jq -r '
  .result.panes[]
  | [.pane_id, (.foreground_cwd // .cwd // ""), (.agent // ""), .workspace_id, .tab_id]
  | @tsv')

# workspace_id -> label, tab_id -> number
ws_labels=$(herdr workspace list 2>/dev/null | jq -r '.result.workspaces[] | [.workspace_id, .label] | @tsv' || true)
tab_numbers=$(herdr tab list 2>/dev/null | jq -r '.result.tabs[] | [.tab_id, (.number|tostring)] | @tsv' || true)

lookup() { # lookup <table> <key>
  printf '%s\n' "$1" | awk -F'\t' -v k="$2" '$1==k {print $2; exit}'
}

busy_panes=()
idle_panes=()
current_in_worktree=0

while IFS=$'\t' read -r pane_id pane_path agent ws_id tab_id; do
  [[ -z "$pane_id" ]] && continue
  pane_path_real="$(cd "$pane_path" 2>/dev/null && pwd -P)" || continue
  case "$pane_path_real" in
    "$wt_path_real"|"$wt_path_real"/*) ;;
    *) continue ;;
  esac

  if [[ "$pane_id" == "${HERDR_PANE_ID:-}" ]]; then
    current_in_worktree=1
    continue
  fi

  rel_path="${pane_path_real#"$wt_path_real"}"
  rel_path="${rel_path#/}"
  [[ -z "$rel_path" ]] && rel_path="."

  # Busy if an agent is attached, or any foreground process is not an idle shell.
  reason=""
  if [[ -n "$agent" ]]; then
    reason="$agent"
  else
    info=$(herdr pane process-info --pane "$pane_id" 2>/dev/null) || info=""
    if [[ -z "$info" ]]; then
      reason="unknown"
    else
      while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        [[ "$name" =~ $IDLE_SHELLS ]] && continue
        reason="$name"
        break
      done < <(printf '%s' "$info" | jq -r '.result.process_info.foreground_processes[]?.argv0 // empty')
    fi
  fi

  if [[ -n "$reason" ]]; then
    busy_panes+=("$pane_id	$(lookup "$ws_labels" "$ws_id")	$(lookup "$tab_numbers" "$tab_id")	$ws_id	$reason	$rel_path")
  else
    idle_panes+=("$pane_id")
  fi
done <<< "$pane_rows"

if [[ ${#busy_panes[@]} -gt 0 ]]; then
  echo "error: busy herdr panes in worktree directory:" >&2
  for entry in "${busy_panes[@]}"; do
    IFS=$'\t' read -r id ws_label tab_num ws_id cmd path <<< "$entry"
    echo "  [${ws_label:-$ws_id}:${tab_num:-?} $id] $cmd ($path)" >&2
    echo "    → herdr workspace focus '$ws_id'" >&2
  done
  echo "Close these agents/applications before proceeding." >&2
  exit 1
fi

for pane_id in ${idle_panes[@]+"${idle_panes[@]}"}; do
  herdr pane close "$pane_id" >/dev/null 2>&1 || true
done

if [[ "$current_in_worktree" == "1" ]]; then
  primary_real="$(cd "$primary_worktree_path" && pwd -P)"
  landing_ws=""
  while IFS=$'\t' read -r pane_id pane_path _agent ws_id _tab_id; do
    [[ -z "$pane_id" ]] && continue
    pane_path_real="$(cd "$pane_path" 2>/dev/null && pwd -P)" || continue
    if [[ "$pane_path_real" == "$primary_real" ]]; then
      landing_ws="$ws_id"
      break
    fi
  done <<< "$pane_rows"

  if [[ -n "$landing_ws" ]]; then
    herdr workspace focus "$landing_ws" >/dev/null 2>&1 || true
  else
    herdr workspace create --cwd "$primary_real" --focus >/dev/null 2>&1 || true
  fi
fi
