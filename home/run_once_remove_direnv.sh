#!/bin/sh

set -e

if command -v direnv >/dev/null 2>&1; then
    echo "Uninstalling direnv via homebrew..."
    brew uninstall direnv || echo "Failed to uninstall direnv via brew, may need manual removal"
fi

if [ -d "$HOME/.config/direnv" ]; then
    echo "Removing direnv config directory: $HOME/.config/direnv"
    rm -rf "$HOME/.config/direnv"
fi

if [ -d "$HOME/.local/share/direnv" ]; then
    echo "Removing direnv data directory: $HOME/.local/share/direnv"
    rm -rf "$HOME/.local/share/direnv"
fi

echo "direnv removal complete"
