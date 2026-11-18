#!/bin/sh
# ~/AGENTS.md is a stray copy of this repo's AGENTS.md, deployed 2025-10-04
# before the source was ignored. .chezmoiignore stops new writes and also
# suppresses .chezmoiremove for the same target, so remove it here instead.
# Claude Code loads AGENTS.md from parent dirs, so the stale guide leaks into
# every session under ~/dev.

set -e

target="$HOME/AGENTS.md"

# Only delete if it's the dotfiles guide, not a file the user wrote since.
if [ -f "$target" ] && head -n1 "$target" | grep -q '^# Chezmoi Dotfiles - Development Guide'; then
    echo "Removing stray $target"
    rm -f "$target"
fi
