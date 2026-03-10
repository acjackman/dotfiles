#!/bin/zsh
# ovim terminal launcher script
#
# Uses zsh so PATH and environment from .zshrc are available.
#
# Available environment variables:
#   OVIM_SESSION_ID - unique session ID (required for IPC callbacks)
#   OVIM_FILE       - temp file path to edit
#   OVIM_EDITOR     - configured editor executable
#   OVIM_SOCKET     - RPC socket path (for live sync)
#   OVIM_TERMINAL   - selected terminal type
#   OVIM_WIDTH      - popup width in pixels
#   OVIM_HEIGHT     - popup height in pixels
#   OVIM_X          - popup x position
#   OVIM_Y          - popup y position

# Fallthrough to normal terminal flow
"$OVIM_CLI" launcher-fallthrough --session "$OVIM_SESSION_ID"
