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

# Check if a Ghostty window already has this session, activate it if so
found=$(osascript -e '
tell application "System Events"
    tell process "Ghostty"
        set windowNames to name of every window
        repeat with i from 1 to count of windowNames
            if item i of windowNames contains "'"$session_name"'" then
                perform action "AXRaise" of window i
                return "found"
            end if
        end repeat
    end tell
end tell
return "not_found"
' 2>/dev/null)

if [[ "$found" == "found" ]]; then
    osascript -e 'tell application "Ghostty" to activate'
else
    # Open a new Ghostty window and attach to the new session
    osascript -e '
tell application "Ghostty"
    activate
end tell

tell application "System Events"
    tell process "Ghostty"
        keystroke "n" using command down
        delay 0.5
    end tell
end tell

set the clipboard to "TMUX= exec tmux attach-session -t '"$session_name"'"
tell application "System Events"
    tell process "Ghostty"
        keystroke "v" using command down
        delay 0.1
        key code 36
    end tell
end tell
'
fi
