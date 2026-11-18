#!/usr/bin/env bash
# switch-pane-fzf.sh - fzf pane picker across tmux sessions
#
# Default: busy panes in the current worktree (to help clear blockers before wt remove/merge).
# Bindings widen scope/filter progressively, matching the sesh picker style.
#
# Invocation modes:
#   switch-pane-fzf.sh <cwd> <client>   # called by tmux run-shell binding; opens popup
#   switch-pane-fzf.sh --pick           # runs inside the popup; writes selection to $PANE_SEL_FILE
#   switch-pane-fzf.sh --list           # emits pane list only (used by fzf reload bindings)
#
# Environment (set by reload bindings):
#   PANE_SCOPE   worktree | sessions   (default: worktree)
#   PANE_FILTER  busy | all            (default: busy)

IDLE_SHELLS="^(zsh|bash|fish|sh)$"
SCRIPT=~/.config/tmux/switch-pane-fzf.sh
TAB=$'\t'

# --- Popup picker mode (runs inside display-popup) ---
if [[ "${1:-}" == "--pick" ]] || [[ "${1:-}" == "--list" ]]; then
  list_only=false
  [[ "${1:-}" == "--list" ]] && list_only=true

  scope="${PANE_SCOPE:-worktree}"
  filter="${PANE_FILTER:-busy}"

  wt_real=""
  if [[ "$scope" == "worktree" ]]; then
    wt_path=$(git rev-parse --show-toplevel 2>/dev/null) || scope="sessions"
    [[ -n "${wt_path:-}" ]] && wt_real=$(cd "$wt_path" && pwd -P)
  fi

  gen_list() {
    tmux list-panes -a \
      -F "#{pane_id}${TAB}#{session_name}:#{window_name}.#{pane_index}${TAB}#{pane_current_command}${TAB}#{pane_current_path}" \
      | while IFS=$'\t' read -r pane_id addr cmd path; do
          [[ "$pane_id" == "${TMUX_PANE:-}" ]] && continue

          if [[ -n "$wt_real" ]]; then
            real_path=$(cd "$path" 2>/dev/null && pwd -P) || continue
            case "$real_path" in
              "$wt_real"|"$wt_real"/*) ;;
              *) continue ;;
            esac
            rel="${real_path#"$wt_real"}"
            rel="${rel#/}"
            [[ -z "$rel" ]] && rel="."
          else
            rel="${path/#$HOME/~}"
          fi

          if [[ "$filter" == "busy" ]] && [[ "$cmd" =~ $IDLE_SHELLS ]]; then
            continue
          fi

          printf '[%s] %s (%s)\t%s\t%s\n' "$addr" "$cmd" "$rel" "$addr" "$pane_id"
        done
  }

  if $list_only; then
    gen_list
    exit 0
  fi

  selected=$(gen_list | fzf \
    --no-sort \
    --with-nth=1 \
    --delimiter=$'\t' \
    --border-label ' panes ' \
    --prompt '  ' \
    --header '  ^w worktree  ^s all-sessions  ^a all' \
    --preview='tmux capture-pane -pt {2} -e 2>/dev/null' \
    --preview-window=right:55% \
    --bind "ctrl-w:change-prompt(  )+reload(PANE_SCOPE=worktree PANE_FILTER=busy $SCRIPT --list)" \
    --bind "ctrl-s:change-prompt(  )+reload(PANE_SCOPE=sessions PANE_FILTER=busy $SCRIPT --list)" \
    --bind "ctrl-a:change-prompt(  )+reload(PANE_SCOPE=sessions PANE_FILTER=all  $SCRIPT --list)" \
    2>/dev/null | cut -f2,3) || true

  [[ -n "${PANE_SEL_FILE:-}" ]] && printf '%s' "$selected" > "$PANE_SEL_FILE"
  exit 0
fi

# --- Launcher mode (called by tmux run-shell binding) ---
cwd="${1:-$PWD}"
client="${2:-}"
tmpfile=$(mktemp /tmp/.pane-sel.XXXXXX)

tmux display-popup -w 80% -h 60% -d "$cwd" -E \
  "PANE_SEL_FILE='$tmpfile' $SCRIPT --pick"

selected=$(cat "$tmpfile" 2>/dev/null)
rm -f "$tmpfile"

[[ -z "$selected" ]] && exit 0

# Activate the window and pane in the session, then switch the outer client to it
IFS=$'\t' read -r addr pane_id <<< "$selected"
session="${addr%%:*}"
window="${addr#*:}"; window="${window%.*}"
tmux select-window -t "${session}:${window}"
tmux select-pane -t "$pane_id"
if [[ -n "$client" ]]; then
  tmux switch-client -c "$client" -t "$session"
else
  tmux switch-client -t "$session"
fi
