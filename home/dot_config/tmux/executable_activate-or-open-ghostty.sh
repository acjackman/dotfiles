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

# Only reuse an existing window if the session has attached tmux clients,
# proving a window is actually displaying it. Without this guard a substring
# match on the window title can false-positive and focus the wrong window.
attached_clients=$(tmux list-clients -t "=$session" 2>/dev/null | wc -l | tr -d ' ')
window_id=""

if [[ "$attached_clients" -gt 0 ]]; then
    window_id=$(aerospace list-windows --all 2>/dev/null \
        | awk -F ' \\| ' -v sess="$session" '$2 ~ /Ghostty/ && $3 ~ " " sess "$" {print $1; exit}')
fi

if [[ -n "$window_id" ]]; then
    aerospace focus --window-id "$window_id"
else
    # Open a new Ghostty window and attach to the session
    # Use Ghostty's AppleScript API (1.3.0+) to avoid spawning a separate
    # process and extra Dock icons.
    osascript -e '
tell application "Ghostty"
  set cfg to new surface configuration
  set initial input of cfg to "exec env -u TMUX tmux attach-session -t \"='"$session"'\"\n"
  new window with configuration cfg
end tell
'
fi
