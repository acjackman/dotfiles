#!/usr/bin/env bash
# Find and activate an existing Ghostty window for a tmux session,
# or open a new Ghostty window and attach to it.
# Usage: activate-or-open-ghostty.sh <session_name> [<path>]
#    or: activate-or-open-ghostty.sh --from-file <file>
#        (reads session on line 1, path on line 2, then removes the file)

if [[ "$1" == "--from-file" ]]; then
    file="$2"
    [[ ! -f "$file" ]] && exit 0
    session=$(sed -n '1p' "$file")
    path=$(sed -n '2p' "$file")
    rm -f "$file"
else
    session="$1"
    path="${2:-$HOME}"
fi

# Use aerospace to find a Ghostty window whose title contains the session name
window_id=$(aerospace list-windows --all 2>/dev/null \
    | awk -F ' \\| ' -v sess="$session" '$2 ~ /Ghostty/ && $0 ~ sess {print $1; exit}')

if [[ -n "$window_id" ]]; then
    aerospace focus --window-id "$window_id"
else
    # Open a new Ghostty window and attach to the session
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

set the clipboard to "TMUX= exec tmux attach-session -t '"$session"'"
tell application "System Events"
    tell process "Ghostty"
        keystroke "v" using command down
        delay 0.1
        key code 36
    end tell
end tell
'
fi
