#!/usr/bin/env bash
# Find a window belonging to a worktree and move it into a properly-named session.
# Reads session name (line 1) and worktree path (line 2) from the given file.
# If the session already exists, just switches to it.
# If not, searches all panes for one whose path matches the worktree, moves that
# window into a new session, and switches to it.
# Usage: move-window-from-file.sh <file>

file="$1"
[[ ! -f "$file" ]] && exit 0

session=$(sed -n '1p' "$file")
path=$(sed -n '2p' "$file")
rm -f "$file"

[[ -z "$session" ]] && exit 1

# If session already exists, just switch to it
if tmux has-session -t "=$session" 2>/dev/null; then
    tmux switch-client -t "=$session"
    exit 0
fi

# Find a window with a pane whose current path is inside the worktree
match=$(tmux list-panes -a -F "#{session_name}:#{window_index} #{pane_current_path}" \
    | grep -F "$path" \
    | head -1 \
    | awk '{print $1}')

if [[ -n "$match" ]]; then
    # Create session, move the found window into it, kill placeholder
    placeholder=$(tmux new-session -d -s "$session" -c "$path" -P -F "#{window_id}" 2>/dev/null)
    tmux move-window -s "$match" -t "${session}:"
    [[ -n "$placeholder" ]] && tmux kill-window -t "$placeholder" 2>/dev/null
else
    # No matching window found — just create a new session
    tmux new-session -d -s "$session" -c "$path"
fi

tmux switch-client -t "=$session"
