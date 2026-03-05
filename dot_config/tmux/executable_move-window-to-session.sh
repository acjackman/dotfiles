#!/usr/bin/env bash

# Get session name based on the current pane's directory
pane_path="$1"
session_name=$(tmux-session-name "$pane_path")

# Get current session and window info
current_session="$2"
current_window="$3"

# Create new detached session and capture its initial window so we can kill it after
placeholder=$(tmux new-session -d -s "$session_name" -c "$pane_path" -P -F "#{window_id}" 2>/dev/null)

# Move the current window to the new session
tmux move-window -s "${current_session}:${current_window}" -t "${session_name}:"

# Kill the placeholder window from new-session (only exists if we just created it)
[[ -n "$placeholder" ]] && tmux kill-window -t "$placeholder" 2>/dev/null

# Switch to the new session
tmux switch-client -t "$session_name"
