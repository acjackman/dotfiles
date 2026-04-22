---
description: Spawn a new Claude agent in an isolated worktree via tmux
argument-hint: [--base <ref>] [--repo <path>] [--model <model>] [--session] <task description>
---

# Spawn Claude Agent

Spawn a new Claude agent in an isolated worktree via tmux. Always creates a **tmux window** in the current session.

Each agent gets its own worktree created by worktrunk, so it can work without conflicting with the current session.

## Arguments

$ARGUMENTS contains the task description and optional flags for the new Claude agent.

**Supported flags** (extract these from $ARGUMENTS before deriving the task description):

- `--base <ref>` — Pass through to `spawn-setup-worktree` to create the worktree from a specific git ref
- `--repo <path>` — Target a different repository (see Cross-Repo Tasks below)
- `--model <model>` — Override the automatic model selection
- `--session` — Create a tmux session instead of a window (default: window)

Everything remaining after extracting flags is the task description.

## Cross-Repo Tasks

Sometimes a task belongs in a different repository than the one you're currently working in. Recognize cross-repo tasks when:

- The user provides a path to another repo (e.g., `~/dev/other-project: fix X`)
- Your investigation reveals the fix belongs in a different codebase

Pass `--repo <path>` to `spawn-setup-worktree` to target the other repo. If it's a bare repo managed by worktrunk, a worktree is created there. If it's a regular checkout, the agent runs directly in that directory (no worktree or branch is created — the branch name is only used for tmux naming).

## Available Scripts

These are on PATH:

- **`spawn-setup-worktree`** — Creates or reuses a worktrunk-managed worktree. Returns JSON `{branch, path}`.
- **`spawn-tmux`** — Spawns a tmux window or session and launches an interactive Claude session inside it.
- **`spawn-launch`** — Reads a prompt file and `exec`s into `claude`. Called by `spawn-tmux` internally.

## Pre-flight Checks

Run these checks before proceeding. If any fail, stop and report the issue to the user rather than continuing.

**Step 0a — Derive branch name first** (needed for subsequent checks):
Derive the branch name as described in step 1 below.

**Step 0b — Linear MCP connected** (only if the task references a Linear ticket or issue):
Attempt a lightweight Linear MCP call (e.g., fetch the viewer or a specific issue). If the call fails with a connection or tool-not-found error, stop and tell the user: "Linear MCP is not connected — cannot fetch ticket context. Check your MCP server config or proceed without it."

**Step 0c — Target branch does not already exist**:
Run:
```bash
git branch --list <branch-name>
wt list 2>/dev/null | grep -F "<branch-name>"
```
If the branch already exists as a local branch or a worktree, stop and ask the user: "Branch `<branch-name>` already exists. Reuse it, pick a different name, or cancel?"

**Step 0d — Base branch selection**:
Run:
```bash
git branch --show-current
```
If the current branch is `main` or `master`, proceed normally (no `--base` needed).

If the current branch is something else, check whether it has an open PR:
```bash
gh pr view --json state,title,body --jq '{state,title,body}' 2>/dev/null
```
If there is no open PR (command errors or returns non-OPEN), proceed without `--base`.

If the PR is open, **reason over whether stacking is appropriate** before asking the user. Stacking makes sense when the new task has a meaningful dependency on the current branch — not just topical similarity. Consider:

- **Stack** when the new task builds directly on code introduced in the current branch (new APIs, types, abstractions, schema changes, config structure) that don't yet exist on `main`. The spawned agent would need those changes to be present to do its work correctly.
- **Stack** when the task is explicitly incremental — "also add X", "now do Y for the same feature", "follow-up to this PR".
- **Don't stack** when the task is independent and happens to touch the same area. Topical overlap alone (both touch auth, both touch the same file) is not enough — the question is whether the new work *requires* the in-progress changes to exist.
- **Don't stack** when the current PR is a draft, failing CI, or otherwise not ready to build on.

Make a recommendation with a one-sentence rationale, then confirm: "I'd suggest **stacking on `<branch>`** because `<reason>`. Confirm, or branch from `main` instead?"

**Step 0e — Working tree is clean**:
Run:
```bash
git status --porcelain
```
If there are uncommitted changes, warn the user: "The working tree has uncommitted changes. These won't be visible to the spawned agent (it works in its own worktree). Continue anyway?" Only stop if the user says no.

## Instructions

1. Derive a short, descriptive branch name from the task (lowercase, hyphens, no spaces). For example, "Fix the auth timeout bug" becomes `fix-auth-timeout`. For regular (non-bare) repos targeted via `--repo`, the name is only used for the tmux window — no branch is created.

   **Pick a model** based on task complexity:

   - **`sonnet`** (default) — most tasks: straightforward bug fixes, simple features, config changes, one-file edits, documentation
   - **`opus`** — complex tasks: multi-file refactors, architectural changes, deep reasoning, careful design decisions, unfamiliar codebases, tasks where getting it wrong is costly

   Default to `sonnet` unless the task clearly warrants `opus`.

2. Create (or reuse) the worktree and get its path:

   ```bash
   spawn-setup-worktree <name> [--base <ref>] [--repo <path>]
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

4. Spawn a full interactive Claude session in tmux. Never use `claude -p`/`--print`. The tmux name is
   derived automatically from the worktree path using `tmux-window-name` or
   `tmux-session-name` (consistent with all other tmux naming in the dotfiles).

   Use `--window` (default) or `--session` if the user passed `--session`:

   ```bash
   spawn-tmux --window --name <name> --dir <worktree-path> --prompt <absolute-path-to-prompt-file> [--model <model>]
   ```

5. Confirm to the user:
   - The branch/worktree that was created (or target repo for cross-repo tasks)
   - The prompt file path
   - How to switch:
     - Window: `tmux select-window -t '=<name>'`
     - Session: `tmux switch-client -t '=<name>'`
