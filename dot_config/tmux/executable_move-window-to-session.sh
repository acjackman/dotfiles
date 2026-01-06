#!/usr/bin/env bash

# Get session name based on the current pane's directory
pane_path="$1"
session_name=$(~/.config/tmux/rename-from-repo.sh "$pane_path")

# Get current session and window info
current_session="$2"
current_window="$3"

# Create new detached session (if it already exists, this will fail but we can ignore)
tmux new-session -d -s "$session_name" -c "$pane_path" 2>/dev/null || true

# Move the current window to the new session
tmux move-window -s "${current_session}:${current_window}" -t "${session_name}:"

# Switch to the new session
tmux switch-client -t "$session_name"
