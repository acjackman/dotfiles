#!/usr/bin/env bash

# Get the current pane path from tmux
pane_path="$1"
cd "$pane_path" || exit 1

# Check if we're in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  # Not a git repo - use current directory name
  basename "$pane_path"
  exit 0
fi

git_dir=$(git rev-parse --git-dir)
toplevel=$(git rev-parse --show-toplevel)

# Check if this is a linked worktree (handles both .git/worktrees/ and .bare/worktrees/)
if [[ "$git_dir" == */worktrees/* ]]; then
  # Worktree - use just the worktree name
  basename "$toplevel"
else
  # Main worktree - just use repo name
  basename "$toplevel"
fi
