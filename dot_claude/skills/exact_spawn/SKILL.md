---
description: Spawn a new Claude agent in an isolated worktree via tmux. Use when the user says "spawn", "start an agent", or wants to delegate a task to a parallel Claude session.
allowed-tools:
  - Bash(~/.claude/skills/spawn/spawn-tmux.sh:*)
  - Bash(~/.claude/skills/spawn/setup-worktree.sh:*)
  - Bash(~/.claude/skills/spawn/write-prompt.sh:*)
  - Bash(echo $TMUX:*)
  - Bash(tmux list-windows*)
---

# Spawn Claude Agent

Spawn a new Claude agent in an isolated worktree via tmux. Always creates a **tmux window** in the current session.

Each agent gets its own worktree created by worktrunk, so it can work without conflicting with the current session.

## Arguments

$ARGUMENTS should contain the task description for the new Claude agent.

## Cross-Repo Tasks

Sometimes a task belongs in a different repository than the one you're currently working in. Recognize cross-repo tasks when:

- The user provides a path to another repo (e.g., `~/dev/other-project: fix X`)
- Your investigation reveals the fix belongs in a different codebase

Pass `--repo <path>` to `setup-worktree.sh` to target the other repo. If it's a bare repo managed by worktrunk, a worktree is created there. If it's a regular checkout, the agent runs directly in that directory (no worktree or branch is created — the branch name is only used for tmux naming).

## Instructions

1. Verify tmux is available:

   ```bash
   echo $TMUX
   ```

   If `$TMUX` is empty, tell the user they must be inside a tmux session and stop.

2. Derive a short, descriptive branch name from the task (lowercase, hyphens, no spaces). For example, "Fix the auth timeout bug" becomes `fix-auth-timeout`. For regular (non-bare) repos targeted via `--repo`, the name is only used for the tmux window — no branch is created.

3. Create (or reuse) the worktree and get its path (also available as `spawn-setup-worktree` on PATH):

   ```bash
   ~/.claude/skills/spawn/setup-worktree.sh <name> [--base <ref>] [--repo <path>]
   ```

   The script prints a JSON object. Extract the path:

   ```bash
   jq -r '.path'
   ```

   If the worktree already exists it is reused (with `--base` compatibility check). When `--repo` targets a regular checkout, the script returns a synthetic JSON entry pointing to that directory.

4. Write the prompt file (also available as `spawn-write-prompt` on PATH).
   For cross-repo tasks, include context from the current repo that the agent
   will need — what you discovered, relevant file paths, code snippets, and
   why the fix belongs in the target repo.

   ```bash
   ~/.claude/skills/spawn/write-prompt.sh <worktree-path> <<'PROMPT'
   <full task description>
   PROMPT
   ```

   The script prints the final prompt file path. Use this path in the next step.

5. Spawn a full interactive Claude session in a new tmux window (also available
   as `spawn-tmux` on PATH). Never use `claude -p`/`--print`. The tmux window
   name is derived automatically from the worktree path using
   `tmux-window-name` (consistent with all other tmux naming in the dotfiles).

   ```bash
   ~/.claude/skills/spawn/spawn-tmux.sh --window --name <name> --dir <worktree-path> --prompt <worktree-path>/.tmp/prompt-<datestamp>.md
   ```

6. Confirm to the user:
   - The branch/worktree that was created (or target repo for cross-repo tasks)
   - The prompt file path
   - How to switch: `tmux select-window -t '=<name>'` (the `=` prefix forces exact name matching)
