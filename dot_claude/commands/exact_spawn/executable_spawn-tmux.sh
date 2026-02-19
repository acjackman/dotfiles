#!/usr/bin/env bash
set -euo pipefail

# Spawn a tmux window or session and send a launch command into it.
# Usage: spawn-tmux.sh --window|--session --name <name> --dir <path> --prompt <file>

usage() {
    echo "Usage: spawn-tmux.sh --window|--session --name <name> --dir <path> --prompt <file>"
    exit 1
}

mode="" name="" dir="" prompt=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --window)  mode="window";  shift ;;
        --session) mode="session"; shift ;;
        --name)    name="$2";      shift 2 ;;
        --dir)     dir="$2";       shift 2 ;;
        --prompt)  prompt="$2";    shift 2 ;;
        *) usage ;;
    esac
done

[[ -z "$mode" || -z "$name" || -z "$dir" || -z "$prompt" ]] && usage
[[ ! -d "$dir" ]] && echo "Error: directory '$dir' does not exist" && exit 1
[[ ! -f "$prompt" ]] && echo "Error: prompt file '$prompt' does not exist" && exit 1

launch_script="$HOME/.claude/commands/spawn/launch.sh"

if [[ "$mode" == "window" ]]; then
    tmux new-window -d -n "$name" -c "$dir"
    tmux send-keys -t "$name" "$launch_script '$prompt'" Enter
elif [[ "$mode" == "session" ]]; then
    tmux new-session -d -s "$name" -c "$dir"
    tmux send-keys -t "$name" "$launch_script '$prompt'" Enter
fi

echo "Spawned $mode '$name' in $dir"
