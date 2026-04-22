---
description: Create or reuse a worktrunk-managed worktree. Use when the user says "worktree", "create a worktree", or needs an isolated branch for a sub-agent.
allowed-tools:
  - Bash(~/.claude/skills/worktree/setup-worktree.sh:*)
---

# Worktree

Create or reuse a worktrunk-managed worktree and return its path.

## Arguments

$ARGUMENTS should contain a branch name, optionally followed by `--base <ref>`.

## Instructions

1. Run the setup script:

   ```bash
   ~/.claude/skills/worktree/setup-worktree.sh <branch> [--base <ref>]
   ```

2. Extract the path from the JSON output using `jq -r '.path'`.

3. Report the worktree path back to the caller.
