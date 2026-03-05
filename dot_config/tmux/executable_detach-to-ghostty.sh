#!/usr/bin/env bash
# Tear the current tmux window out into a new session in a new Ghostty window.
# Usage: detach-to-ghostty.sh <pane_current_path> <session_name> <window_index>

pane_path="$1"
current_session="$2"
current_window="$3"

# Name the new session based on the worktree/repo
session_name=$(tmux-session-name "$pane_path")

# Create new detached session and capture its initial window so we can kill it after
placeholder=$(tmux new-session -d -s "$session_name" -c "$pane_path" -P -F "#{window_id}" 2>/dev/null)

# Move the current window to the new session
tmux move-window -s "${current_session}:${current_window}" -t "${session_name}:"

# Kill the placeholder window from new-session (only exists if we just created it)
[[ -n "$placeholder" ]] && tmux kill-window -t "$placeholder" 2>/dev/null

# Find existing Ghostty window or open a new one
~/.config/tmux/activate-or-open-ghostty.sh "$session_name" "$pane_path"
