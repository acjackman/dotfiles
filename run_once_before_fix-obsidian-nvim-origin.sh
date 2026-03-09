#!/bin/bash
# Remove obsidian.nvim lazy plugin if it points to the old epwalsh fork,
# so Lazy.nvim re-clones from obsidian-nvim/obsidian.nvim.

PLUGIN_DIR="$HOME/.local/share/nvim/lazy/obsidian.nvim"

if [ ! -d "$PLUGIN_DIR/.git" ]; then
    exit 0
fi

origin=$(git -C "$PLUGIN_DIR" remote get-url origin 2>/dev/null)
if echo "$origin" | grep -q "epwalsh/obsidian.nvim"; then
    echo "Removing obsidian.nvim with old origin: $origin"
    rm -rf "$PLUGIN_DIR"
fi
