#!/usr/bin/env bash
# Thin wrapper — delegates to tmux-window-name for consistent naming.
exec tmux-window-name "${1:-.}"
