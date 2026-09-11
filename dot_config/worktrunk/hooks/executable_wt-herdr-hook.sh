#!/usr/bin/env bash
# wt-herdr-hook.sh - Pre-remove/merge hook: clean up herdr panes in the worktree
#
# Herdr counterpart to wt-tmux-hook.sh.
# Reads worktree_path from stdin JSON (worktrunk hook context).
# Idle shell panes are closed; busy panes (an attached agent, or any non-shell
# foreground process) cause an error that aborts the operation.
# The pane that ran `wt remove` is left alone: worktrunk's shell integration cds it
# to the primary worktree itself, so this hook must not focus or create a workspace.

set -euo pipefail

IDLE_SHELLS="^-?(zsh|bash|fish|sh)$"

ctx=$(cat)
worktree_path=$(printf '%s' "$ctx" | jq -r '.worktree_path')

command -v herdr >/dev/null 2>&1 || exit 0
[[ -S "${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}" ]] || exit 0

panes_json=$(herdr pane list 2>/dev/null) || exit 0

wt_path_real="$(cd "$worktree_path" && pwd -P)"

# $HERDR_PANE_ID can be stale: pane ids are reassigned (server restart,
# workspace re-create) and a long-lived process keeps the old value in its
# environment. The server still resolves the old id, but `pane list` reports
# the new one, so compare canonical ids. Resolve only when the env var is set:
# `pane current` with no --pane returns the *focused* pane, which is not us.
self_pane_id="${HERDR_PANE_ID:-}"
if [[ -n "$self_pane_id" ]]; then
  resolved_pane_id=$(herdr pane current --pane "$self_pane_id" 2>/dev/null \
    | jq -r '.result.pane.pane_id // empty') || resolved_pane_id=""
  [[ -n "$resolved_pane_id" ]] && self_pane_id="$resolved_pane_id"
fi

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

while IFS=$'\t' read -r pane_id pane_path agent ws_id tab_id; do
  [[ -z "$pane_id" ]] && continue
  pane_path_real="$(cd "$pane_path" 2>/dev/null && pwd -P)" || continue
  case "$pane_path_real" in
    "$wt_path_real"|"$wt_path_real"/*) ;;
    *) continue ;;
  esac

  # Skip our own pane: worktrunk emits a `cd <primary>` shell directive for it
  # (src/output/handlers.rs, `if changed_directory`), so it relocates itself.
  if [[ -n "$self_pane_id" && "$pane_id" == "$self_pane_id" ]]; then
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
