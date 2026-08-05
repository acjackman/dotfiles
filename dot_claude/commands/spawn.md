---
description: Spawn a new Claude agent in an isolated worktree on a herdr (or tmux) surface
argument-hint: [--base <ref>] [--repo <path>] [--model <model>] [--session] <task description>
---

# Spawn Claude Agent

Spawn a new Claude agent in an isolated worktree on a new interactive surface. You open that surface by driving **herdr** directly — or **tmux**, if that's the multiplexer you're actually running inside. Detect which; don't assume (see step 0f).

Each agent gets its own worktree created by worktrunk, so it can work without conflicting with the current session.

## Arguments

$ARGUMENTS contains the task description and optional flags for the new Claude agent.

**Supported flags** (extract these from $ARGUMENTS before deriving the task description):

- `--base <ref>` — Pass through to `spawn-setup-worktree` to create the worktree from a specific git ref
- `--repo <path>` — Target a different repository (see Cross-Repo Tasks below)
- `--model <model>` — Override the automatic model selection
- `--session` — On tmux, create a session instead of a window (default: window). Ignored on herdr, which always opens an isolated workspace per agent.

Everything remaining after extracting flags is the task description.

## Cross-Repo Tasks

Sometimes a task belongs in a different repository than the one you're currently working in. Recognize cross-repo tasks when:

- The user provides a path to another repo (e.g., `~/dev/other-project: fix X`)
- Your investigation reveals the fix belongs in a different codebase

Pass `--repo <path>` to `spawn-setup-worktree` to target the other repo. If it's a bare repo managed by worktrunk, a worktree is created there. If it's a regular checkout, the agent runs directly in that directory (no worktree or branch is created — the branch name is only used for tmux naming).

## Available Scripts

These are on PATH:

- **`spawn-setup-worktree`** — Creates or reuses a worktrunk-managed worktree. Returns JSON `{branch, path}`.
- **`herdr`** — The multiplexer. `herdr workspace create` opens an isolated workspace, `herdr pane run` launches a command in it, `herdr agent list` reports semantic agent state, `herdr workspace close` tears it down. Most commands return JSON — read IDs out of the response with `jq` rather than predicting them.
- **`tmux`** — The fallback, used only when you're actually running inside tmux (or herdr's server is down).

> The `clank` adapter was **removed** on 2026-08-04. Drive `herdr`/`tmux` directly as described below.

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

**Step 0f — Pick the substrate**:
Detect it, in this order. Never cross multiplexers — a surface opened from inside tmux stays in tmux, and vice versa.

```bash
herdr pane current >/dev/null 2>&1 && echo herdr        # inside a herdr pane
[ -n "$TMUX" ] && echo tmux                             # inside tmux
herdr status server >/dev/null 2>&1 && echo herdr || echo tmux   # no host context
```

Probe with `herdr pane current`, **not** `$HERDR_ENV`/`$HERDR_SESSION` — those are ordinary env vars that a child process can inherit from a *different* live pane, so they lie. If neither multiplexer is available, stop and tell the user.

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

4. Spawn a full interactive Claude session on a new surface. Never use `claude -p`/`--print`.

   Use the **branch name** as the label throughout — the herdr workspace label, the tmux window name, and `claude --name` — so all three identifiers line up and a human can find the agent by one name. (Don't name it after the worktree basename: most doers spawn in `.../infra/main`, which collapses every session to `main`.)

   Build the launch line once:

   ```bash
   LAUNCH="cat <absolute-path-to-prompt-file> | claude --permission-mode=auto --name <branch-name> --settings '{\"enableAllProjectMcpServers\":true}' --model <model>"
   ```

   `enableAllProjectMcpServers` stops the agent stalling on the "N new MCP servers found — enable?" prompt for an unapproved project `.mcp.json`. It auto-approves *project*-scoped servers only, leaving global/user MCP intact.

   **On herdr** — one isolated workspace per agent, opened in the background:

   ```bash
   ws_json=$(herdr workspace create --cwd <worktree-path> --label <branch-name> --no-focus)
   ws=$(jq -r '.result.workspace.workspace_id' <<<"$ws_json")
   pane=$(jq -r '.result.root_pane.pane_id'    <<<"$ws_json")
   herdr pane run "$pane" "unset TMUX TMUX_PANE; $LAUNCH"
   ```

   Unset `$TMUX` in the launch line: the herdr server can carry a stale one that every pane inherits, which breaks `tmux display-popup` (revdiff) inside a surface that isn't actually a tmux client. `pane run` types the line into the workspace's shell and presses Enter, so that shell evaluates the pipe.

   **On tmux** — a background window, or a session if the user passed `--session`:

   ```bash
   pane=$(tmux new-window -n <branch-name> -c <worktree-path> -d -P -F '#{pane_id}')
   # ...or, with --session:
   pane=$(tmux new-session -d -s <branch-name> -c <worktree-path> -P -F '#{pane_id}')
   tmux set-option -t "$pane" automatic-rename off
   tmux set-option -p -t "$pane" @agent_label <branch-name>   # -p, or it leaks session-wide
   tmux send-keys -t "$pane" "$LAUNCH" Enter
   ```

   Record the substrate and the ids (`ws` / `pane`) for the next steps.

5. **Verify the agent actually started** (don't trust the spawn step blindly).
   Wait ~3 seconds for shell init + claude startup, then ask for the agent's state.

   **On herdr** — semantic state, joined through the workspace id:

   ```bash
   sleep 3
   herdr agent list | jq -c --arg ws "$ws" '.result.agents[] | select(.workspace_id==$ws) | {agent, agent_status, pane_id}'
   ```

   - `working`, `idle`, or `blocked` — the agent is up, proceed. (`blocked` this
     early usually means a permission/trust prompt is waiting — worth mentioning
     to the user.)
   - no matching agent, or `done`/`unknown` — claude failed to launch or exited
     immediately. `unknown` means herdr sees *something* it can't classify; it is
     not evidence of success. Read the buffer to diagnose:

     ```bash
     herdr pane read "$pane" --lines 30
     ```

   **On tmux** — there is no semantic state, so read the buffer directly and judge:

   ```bash
   sleep 3
   tmux capture-pane -t "$pane" -p | tail -30
   ```

   Either way:

     Known failure signals — any of these means the spawn did NOT succeed and
     you must report the failure verbatim instead of claiming success:

     - `mise ERROR` / `Config files ... are not trusted` — `.mise.toml` trust hook missed
     - `command not found` — `claude` or another tool is missing from PATH inside that surface
     - `No such file or directory` referencing the prompt file

6. Confirm to the user:
   - The branch/worktree that was created (or target repo for cross-repo tasks)
   - The **substrate** the agent was spawned on (herdr or tmux) and its label
   - The prompt file path
   - How to switch to it:
     - **herdr**: `herdr workspace focus <workspace_id>` (or open the workspace
       picker with `prefix o` and pick it by its `<branch-name>` label)
     - **tmux window**: `tmux select-window -t '=<branch-name>'`
     - **tmux session**: `tmux switch-client -t '=<branch-name>'`

7. When the agent's work has been merged/handled and the surface is no longer
   needed, tear it down.

   **On herdr** — close by **workspace id**, re-resolved right now. Labels are
   not unique, so closing by label can tear down the wrong surface:

   ```bash
   herdr workspace list | jq -r --arg l '<branch-name>' \
     '.result.workspaces[] | select(.label==$l) | .workspace_id'
   herdr workspace close <workspace_id>
   ```

   If that lookup returns more than one id, **stop and ask** which surface to
   close — don't guess. If it returns none, the workspace is already gone.

   **On tmux**:

   ```bash
   tmux kill-window -t "$pane"     # or: tmux kill-session -t '=<branch-name>'
   ```
