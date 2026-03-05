#!/usr/bin/env bash
# Tear the current tmux window out into a new session in a new Ghostty window.
# TODO: handle non-git paths (currently tmux-session-name falls back to basename)
# Usage: detach-to-ghostty.sh <pane_current_path> <session_name> <window_index>

pane_path="$1"
current_session="$2"
current_window="$3"

# Name the new session based on the worktree/repo
session_name=$(tmux-session-name "$pane_path")

# Already in the right session — just signal Ghostty activation
if [[ "$current_session" == "$session_name" ]]; then
    printf '%s\n%s\n' "$session_name" "$pane_path" > /tmp/wt-ghostty-pending
    exit 0
fi

# If session exists, move the current window into it
if tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux move-window -s "${current_session}:${current_window}" -t "${session_name}:"
    printf '%s\n%s\n' "$session_name" "$pane_path" > /tmp/wt-ghostty-pending
    exit 0
fi

# Create new session, move the current window into it, kill placeholder
placeholder=$(tmux new-session -d -s "$session_name" -c "$pane_path" -P -F "#{window_id}" 2>/dev/null)
tmux move-window -s "${current_session}:${current_window}" -t "${session_name}:"
[[ -n "$placeholder" ]] && tmux kill-window -t "$placeholder" 2>/dev/null

printf '%s\n%s\n' "$session_name" "$pane_path" > /tmp/wt-ghostty-pending
