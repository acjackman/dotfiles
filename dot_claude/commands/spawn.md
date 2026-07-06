---
description: Spawn a new Claude agent in an isolated worktree via tmux
argument-hint: [--base <ref>] [--repo <path>] [--model <model>] [--session] <task description>
---

# Spawn Claude Agent

Spawn a new Claude agent in an isolated worktree on a new interactive surface. The surface is opened by the `fleet` substrate adapter, which uses **herdr** when it's the active multiplexer and falls back to **tmux** otherwise (see "Substrate" below) — you don't choose; `fleet` dispatches on context.

Each agent gets its own worktree created by worktrunk, so it can work without conflicting with the current session.

## Arguments

$ARGUMENTS contains the task description and optional flags for the new Claude agent.

**Supported flags** (extract these from $ARGUMENTS before deriving the task description):

- `--base <ref>` — Pass through to `spawn-setup-worktree` to create the worktree from a specific git ref
- `--repo <path>` — Target a different repository (see Cross-Repo Tasks below)
- `--model <model>` — Override the automatic model selection
- `--session` — On the tmux backend, create a session instead of a window (default: window). Ignored on herdr, which always opens an isolated workspace per agent.

Everything remaining after extracting flags is the task description.

## Cross-Repo Tasks

Sometimes a task belongs in a different repository than the one you're currently working in. Recognize cross-repo tasks when:

- The user provides a path to another repo (e.g., `~/dev/other-project: fix X`)
- Your investigation reveals the fix belongs in a different codebase

Pass `--repo <path>` to `spawn-setup-worktree` to target the other repo. If it's a bare repo managed by worktrunk, a worktree is created there. If it's a regular checkout, the agent runs directly in that directory (no worktree or branch is created — the branch name is only used for tmux naming).

## Available Scripts

These are on PATH:

- **`spawn-setup-worktree`** — Creates or reuses a worktrunk-managed worktree. Returns JSON `{branch, path}`.
- **`fleet`** — Substrate adapter. `fleet spawn` opens a new surface (herdr workspace or tmux window/session, by context) and launches an interactive Claude session inside it (pipes the prompt file into `claude`), tagging it with a `--label` for tracking. `fleet state <label>` reports the agent's semantic state. `fleet backend` prints which backend the current context resolves to.

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

4. Spawn a full interactive Claude session on a new surface. Never use `claude -p`/`--print`. Use the **branch name** as the tracking `--label` (the effort/ticket-id convention `fleet state` keys on). `fleet` chooses herdr or tmux by context and, on tmux, derives the window/session name from the worktree path automatically.

   Pass `--session` only if the user passed it (tmux-only; herdr ignores it):

   ```bash
   fleet spawn --cwd <worktree-path> --label <branch-name> --prompt <absolute-path-to-prompt-file> [--model <model>] [--session]
   ```

   `fleet spawn` prints `substrate:`, `label:`, `handle:` and backend ids — capture `substrate` and `label` for the next steps.

5. **Verify the agent actually started** (don't trust the spawn step blindly).
   Wait ~3 seconds for shell init + claude startup, then ask the adapter for the
   agent's state:

   ```bash
   sleep 3
   fleet state <branch-name>
   ```

   This prints a JSON object with a `state` field:

   - `working`, `idle`, or `blocked` — the agent is up, proceed. (`blocked` this
     early usually means a permission/trust prompt is waiting — worth mentioning
     to the user.)
   - `done` or `unknown`, or `state:"none"` / exit code 3 (label not found) —
     claude failed to launch or exited immediately. On the tmux backend, capture
     the pane's buffer for diagnosis (get the pane id from the `fleet state`
     output, or from `fleet list`):

     ```bash
     tmux capture-pane -t '<pane_id>' -p | tail -30
     ```

     On herdr, read the pane buffer instead (use the `pane_id` from the
     `fleet state` / `fleet spawn` output — herdr's `agent` targets are keyed by
     agent name/pane, not by our workspace label):

     ```bash
     herdr pane read <pane_id> --lines 30
     ```

     Known failure signals — any of these means the spawn did NOT succeed and
     you must report the failure verbatim instead of claiming success:

     - `mise ERROR` / `Config files ... are not trusted` — `.mise.toml` trust hook missed
     - `command not found` — `claude` or another tool is missing from PATH inside that surface
     - `No such file or directory` referencing the prompt file

6. Confirm to the user:
   - The branch/worktree that was created (or target repo for cross-repo tasks)
   - The **substrate** the agent was spawned on (herdr or tmux) and its label
   - The prompt file path
   - How to switch to it (use the ids from the `fleet spawn` output):
     - **herdr**: `herdr workspace focus <workspace_id>` (or open the workspace
       picker with `prefix o` and pick it by its `<branch-name>` label)
     - **tmux window**: `tmux select-window -t '=<handle>'`
     - **tmux session**: `tmux switch-client -t '=<handle>'`
