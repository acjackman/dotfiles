#!/usr/bin/env bash
# TODO: handle non-git paths (currently tmux-session-name falls back to basename)

# Relocate the current window to its project (bare repo) session, dropping any
# branch suffix so a stray worktree window lands in the right project session.
pane_path="$1"
session_name=$(tmux-session-name --repo "$pane_path")

# Get current session and window info
current_session="$2"
current_window="$3"

# Already in the right session — nothing to do
if [[ "$current_session" == "$session_name" ]]; then
    exit 0
fi

# Rename the window from its repo/worktree so it matches sibling windows
window_name=$(~/.config/tmux/rename-from-repo.sh "$pane_path")
[[ -n "$window_name" ]] && tmux rename-window -t "${current_session}:${current_window}" "$window_name"

# If session exists, move the current window into it
if tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux move-window -s "${current_session}:${current_window}" -t "${session_name}:"
    tmux switch-client -t "=$session_name"
    exit 0
fi

# Create new session, move the current window into it, kill placeholder
placeholder=$(tmux new-session -d -s "$session_name" -c "$pane_path" -P -F "#{window_id}" 2>/dev/null)
tmux move-window -s "${current_session}:${current_window}" -t "${session_name}:"
[[ -n "$placeholder" ]] && tmux kill-window -t "$placeholder" 2>/dev/null

tmux switch-client -t "=$session_name"
