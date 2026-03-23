---
description: Spawn a new Claude agent in an isolated worktree via tmux. Use when the user says "spawn", "start an agent", or wants to delegate a task to a parallel Claude session.
---

# Spawn Claude Agent

Spawn a new Claude agent in an isolated worktree via tmux. Always creates a **tmux window** in the current session.

Each agent gets its own worktree created by worktrunk, so it can work without conflicting with the current session.

## Arguments

$ARGUMENTS contains the task description and optional flags for the new Claude agent.

**Supported flags** (extract these from $ARGUMENTS before deriving the task description):

- `--base <ref>` — Pass through to `setup-worktree.sh` to create the worktree from a specific git ref
- `--repo <path>` — Target a different repository (see Cross-Repo Tasks below)
- `--model <model>` — Override the automatic model selection
- `--session` — Create a tmux session instead of a window (default: window)

Everything remaining after extracting flags is the task description.

## Cross-Repo Tasks

Sometimes a task belongs in a different repository than the one you're currently working in. Recognize cross-repo tasks when:

- The user provides a path to another repo (e.g., `~/dev/other-project: fix X`)
- Your investigation reveals the fix belongs in a different codebase

Pass `--repo <path>` to `setup-worktree.sh` to target the other repo. If it's a bare repo managed by worktrunk, a worktree is created there. If it's a regular checkout, the agent runs directly in that directory (no worktree or branch is created — the branch name is only used for tmux naming).

## Available Scripts

- **`setup-worktree.sh`** — Creates or reuses a worktrunk-managed worktree. Returns JSON `{branch, path}`. Also on PATH as `spawn-setup-worktree`.
- **`spawn-tmux.sh`** — Spawns a tmux window or session and launches an interactive Claude session inside it. Also on PATH as `spawn-tmux`.
- **`launch.sh`** — Reads a prompt file and `exec`s into `claude`. Called by `spawn-tmux.sh` internally.

## Instructions

1. Derive a short, descriptive branch name from the task (lowercase, hyphens, no spaces). For example, "Fix the auth timeout bug" becomes `fix-auth-timeout`. For regular (non-bare) repos targeted via `--repo`, the name is only used for the tmux window — no branch is created.

   **Pick a model** based on task complexity:

   - **`sonnet`** (default) — most tasks: straightforward bug fixes, simple features, config changes, one-file edits, documentation
   - **`opus`** — complex tasks: multi-file refactors, architectural changes, deep reasoning, careful design decisions, unfamiliar codebases, tasks where getting it wrong is costly

   Default to `sonnet` unless the task clearly warrants `opus`.

2. Create (or reuse) the worktree and get its path (also available as `spawn-setup-worktree` on PATH):

   ```bash
   ${CLAUDE_SKILL_DIR}/setup-worktree.sh <name> [--base <ref>] [--repo <path>]
   ```

   The script prints a JSON object. Extract the path:

   ```bash
   jq -r '.path'
   ```

   If the worktree already exists it is reused (with `--base` compatibility check). When `--repo` targets a regular checkout, the script returns a synthetic JSON entry pointing to that directory.

3. Write the prompt file using the **Write** tool (not Bash).
   Use the Write tool to create a file at `<cwd>/.tmp/prompt-<YYYY-MM-DD-HHMMSS>.md`
   (where `<cwd>` is your current working directory, as an absolute path).
   The spawned agent has no conversation history — the prompt must be
   **self-contained**. Expand the user's request into a complete task
   description: include relevant context, file paths, and any details the
   agent will need to work independently. Do not just pass through the raw
   user input verbatim.
   For cross-repo tasks, include context from the current repo that the agent
   will need — what you discovered, relevant file paths, code snippets, and
   why the fix belongs in the target repo.

   Remember the absolute path to this file for the next step.

4. Spawn a full interactive Claude session in tmux (also available as
   `spawn-tmux` on PATH). Never use `claude -p`/`--print`. The tmux name is
   derived automatically from the worktree path using `tmux-window-name` or
   `tmux-session-name` (consistent with all other tmux naming in the dotfiles).

   Use `--window` (default) or `--session` if the user passed `--session`:

   ```bash
   ${CLAUDE_SKILL_DIR}/spawn-tmux.sh --window --name <name> --dir <worktree-path> --prompt <absolute-path-to-prompt-file> [--model <model>]
   ```

5. Confirm to the user:
   - The branch/worktree that was created (or target repo for cross-repo tasks)
   - The prompt file path
   - How to switch:
     - Window: `tmux select-window -t '=<name>'`
     - Session: `tmux switch-client -t '=<name>'`
