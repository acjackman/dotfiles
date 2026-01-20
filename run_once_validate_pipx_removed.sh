#!/bin/sh

set -e

errors=0

if command -v pipx >/dev/null 2>&1; then
    echo "ERROR: pipx is still installed: $(command -v pipx)"
    errors=$((errors + 1))
fi

if [ -d "$HOME/.local/pipx" ]; then
    echo "ERROR: pipx data directory still exists: $HOME/.local/pipx"
    errors=$((errors + 1))
fi

if [ $errors -gt 0 ]; then
    echo "pipx validation failed with $errors error(s)"
    exit 1
fi

echo "pipx has been removed"
