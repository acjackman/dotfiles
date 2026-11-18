#!/bin/bash
# Save current directory to return to later
CURRENT_DIR=$(pwd)

for dir in ${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/*; do
    cd $dir
    if [ ! -d "$dir" ]; then
        continue
    fi

    # Check if it's a git repository
    if [ ! -d "$dir/.git" ]; then
        continue
    fi

    # Check for uncommitted changes
    if git status --porcelain | grep -q .; then
        echo "WARNING: $dir has uncommitted changes"
    fi

    # Check if repo is ahead of origin
    if git rev-list @{u}..HEAD | grep -q .; then
        echo "WARNING: $dir is ahead of origin - you may want to push your changes"
    fi

    # Check if pre-commit hook is already installed
    if [ -f "$dir/.git/hooks/pre-commit" ]; then
        continue
    fi

    # Check if .pre-commit-config.yaml exists
    if [ ! -f "$dir/.pre-commit-config.yaml" ]; then
        continue
    fi

    # Install pre-commit hooks
    echo "Installing pre-commit hooks in $dir"
    pre-commit install

done

cd $CURRENT_DIR
