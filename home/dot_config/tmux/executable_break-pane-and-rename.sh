#!/usr/bin/env bash

# Get the name based on current directory
pane_path="$1"
window_name=$(~/.config/tmux/rename-from-repo.sh "$pane_path")

# Break the pane into a new window
tmux break-pane

# Rename the newly created window
tmux rename-window "$window_name"
