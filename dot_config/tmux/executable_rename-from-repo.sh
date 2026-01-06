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
  # Extract the path before /worktrees/
  # For .git/worktrees/ or .bare/worktrees/
  base_path="${git_dir%/worktrees/*}"

  # Get the repo directory (parent of .git or .bare)
  main_repo_path=$(dirname "$base_path")
  repo_name=$(basename "$main_repo_path")
  worktree_name=$(basename "$toplevel")
  echo "$repo_name/$worktree_name"
else
  # Main worktree - just use repo name
  basename "$toplevel"
fi
