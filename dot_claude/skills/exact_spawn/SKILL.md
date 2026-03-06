---
description: Spawn a new Claude agent in an isolated worktree via tmux. Use when the user says "spawn", "start an agent", or wants to delegate a task to a parallel Claude session.
allowed-tools:
  - Bash(~/.claude/skills/spawn/spawn-tmux.sh:*)
  - Bash(~/.claude/skills/spawn/setup-worktree.sh:*)
  - Bash(~/.claude/skills/spawn/write-prompt.sh:*)
  - Bash(echo $TMUX:*)
  - Bash(tmux list-sessions*)
  - Bash(tmux list-windows*)
---

# Spawn Claude Agent

Spawn a new Claude agent in an isolated worktree via tmux.

Each agent gets its own worktree created by worktrunk, so it can work without conflicting with the current session.

## Arguments

$ARGUMENTS should contain the task description for the new Claude agent.

## Cross-Repo Tasks

Sometimes a task belongs in a different repository than the one you're currently working in. Recognize cross-repo tasks when:

- The user provides a path to another repo (e.g., `~/dev/other-project: fix X`)
- Your investigation reveals the fix belongs in a different codebase

Cross-repo tasks default to a **new session** (not window), since they represent independent work in a separate project.

Pass `--repo <path>` to `setup-worktree.sh` to target the other repo. If it's a bare repo managed by worktrunk, a worktree is created there. If it's a regular checkout, the agent runs directly in that directory (no worktree or branch is created — the branch name is only used for tmux naming).

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

3. Derive a short, descriptive branch name from the task (lowercase, hyphens, no spaces). For example, "Fix the auth timeout bug" becomes `fix-auth-timeout`. For regular (non-bare) repos targeted via `--repo`, the name is only used for the tmux window/session — no branch is created.

4. Create (or reuse) the worktree and get its path (also available as `spawn-setup-worktree` on PATH):

   ```bash
   ~/.claude/skills/spawn/setup-worktree.sh <name> [--base <ref>] [--repo <path>]
   ```

   The script prints a JSON object. Extract the path:

   ```bash
   jq -r '.path'
   ```

   If the worktree already exists it is reused (with `--base` compatibility check). When `--repo` targets a regular checkout, the script returns a synthetic JSON entry pointing to that directory.

5. Write the prompt file (also available as `spawn-write-prompt` on PATH).
   For cross-repo tasks, include context from the current repo that the agent
   will need — what you discovered, relevant file paths, code snippets, and
   why the fix belongs in the target repo.

   ```bash
   ~/.claude/skills/spawn/write-prompt.sh <worktree-path> <<'PROMPT'
   <full task description>
   PROMPT
   ```

   The script prints the final prompt file path. Use this path in the next step.

6. Spawn a full interactive Claude session (also available as `spawn-tmux` on
   PATH). Never use `claude -p`/`--print`. The tmux window/session name is
   derived automatically from the worktree path using `tmux-window-name` or
   `tmux-session-name` (consistent with all other tmux naming in the dotfiles).

   **Window:**
   ```bash
   ~/.claude/skills/spawn/spawn-tmux.sh --window --name <name> --dir <worktree-path> --prompt <worktree-path>/.tmp/prompt-<datestamp>.md
   ```

   **Session:**
   ```bash
   ~/.claude/skills/spawn/spawn-tmux.sh --session --name <name> --dir <worktree-path> --prompt <worktree-path>/.tmp/prompt-<datestamp>.md
   ```

7. Confirm to the user:
   - Whether a window or session was created
   - The branch/worktree that was created (or target repo for cross-repo tasks)
   - The prompt file path
   - How to switch: `tmux select-window -t '=<name>'` or `tmux switch-client -t '=<name>'` (the `=` prefix forces exact name matching)
