---
allowed-tools:
  - Bash(tmux new-session:*)
  - Bash(tmux new-window:*)
  - Bash(echo $TMUX:*)
  - Bash(tmux list-sessions:*)
  - Bash(tmux list-windows:*)
  - Bash(/opt/homebrew/bin/wt switch:*)
  - Bash(/opt/homebrew/bin/wt list:*)
  - Bash(~/.claude/commands/spawn/setup-worktree.sh:*)
  - Bash(mkdir:*)
---

# Spawn Claude Agent

Spawn a new Claude agent in an isolated worktree via tmux.

Each agent gets its own worktree created by worktrunk, so it can work without conflicting with the current session.

## Arguments

$ARGUMENTS should contain the task description for the new Claude agent.

## Instructions

1. Verify tmux is available:

   ```bash
   echo $TMUX
   ```

   If `$TMUX` is empty, tell the user they must be inside a tmux session and stop.

2. Analyze the task to choose session vs window:

   **Use a new window** (small, focused tasks):
   - Single-file changes, bug fixes, quick refactors
   - Tasks scoped to one module or component
   - Short-lived work that will finish quickly

   **Use a new session** (large, independent tasks):
   - Multi-file or cross-cutting changes
   - Feature implementation, large refactors
   - Long-running tasks you may want to revisit later
   - Tasks in a different project or directory

   Briefly tell the user which you chose and why.

3. Derive a short, descriptive branch name from the task (lowercase, hyphens, no spaces). For example, "Fix the auth timeout bug" becomes `fix-auth-timeout`.

4. Check for tmux name conflicts **before** creating the worktree:

   ```bash
   tmux list-sessions   # if spawning a session
   tmux list-windows    # if spawning a window
   ```

   If the name is already taken, pick a more descriptive alternative now that you can see the existing names. Do not append a numeric suffix.

5. Create (or reuse) the worktree and get its path:

   ```bash
   ~/.claude/commands/spawn/setup-worktree.sh <name> [--base <ref>]
   ```

   The script prints the worktree's JSON entry. Extract the path:

   ```bash
   jq -r '.path'
   ```

   If the worktree already exists it is reused (with `--base` compatibility check).

6. Write the prompt to a datestamped file inside the worktree:

   ```bash
   mkdir -p <worktree-path>/.tmp
   ```

   Write the task description to `<worktree-path>/.tmp/prompt-<YYYY-MM-DD-HHMMSS>.md`.

7. Spawn a full interactive Claude session. Never use `claude -p`/`--print`.

   **Window:**
   ```bash
   tmux new-window -d -n <name> -c <worktree-path> "~/.claude/commands/spawn/launch.sh <worktree-path>/.tmp/prompt-<datestamp>.md"
   ```

   **Session:**
   ```bash
   tmux new-session -d -s <name> -c <worktree-path> "~/.claude/commands/spawn/launch.sh <worktree-path>/.tmp/prompt-<datestamp>.md"
   ```

8. Confirm to the user:
   - Whether a window or session was created, and its name
   - The branch/worktree that was created
   - The prompt file path
   - How to switch: `tmux select-window -t <name>` or `tmux switch-client -t <name>`
