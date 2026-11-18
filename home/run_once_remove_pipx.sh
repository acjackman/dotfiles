#!/bin/sh

set -e

if command -v pipx >/dev/null 2>&1; then
    echo "Uninstalling pipx via homebrew..."
    brew uninstall pipx || echo "Failed to uninstall pipx via brew, may need manual removal"
fi

if [ -d "$HOME/.local/pipx" ]; then
    echo "Removing pipx data directory: $HOME/.local/pipx"
    rm -rf "$HOME/.local/pipx"
fi

echo "pipx removal complete"
