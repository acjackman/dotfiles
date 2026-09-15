# Git

## Worktree Layout

Repositories use a bare repo + worktree structure:

```
~/dev/project-name/
  .bare/              # The bare repository
  main/               # Worktree for main branch
  feature-branch/     # Worktree for feature branch
```

Worktrees are managed by `worktrunk` (`wt`), not raw `git worktree` commands.

## Worktrunk Commands

```bash
wt switch --create feature-name   # Create worktree and branch
wt switch feature-name            # Switch to existing worktree
wt list                           # Show all worktrees with status
wt remove                         # Remove worktree; delete branch if merged
wt merge                          # Merge current branch into target
```

## The Trunk Checkout Is Read-Only For Branch Work

The `main/` worktree exists so it can always be fast-forwarded and diffed against.
Other sessions share the clone and rely on it being clean and on trunk.

- **Never** run `git switch -c`, `git checkout -b`, `git switch <branch>`, or `git commit`
  while in the trunk checkout. Create a worktree instead: `wt switch --create <branch-name>`
  (or the `/worktree` skill), then do all the work from that path.
- A `PreToolUse` hook (`~/.local/bin/claude-trunk-guard`) denies these. Treat the denial as
  the signal to make a worktree, not as something to route around.
- Already on a feature branch inside the trunk checkout? Move the work out: create the
  worktree, `git switch main` in the trunk checkout, continue in the worktree.
- Read-only git and `git worktree add` are always fine.
- Escape hatch: a repo that must commit on trunk from a fixed path (chezmoi's source
  dir, `~/.local/share/chezmoi`) is exempt. Any other repo can opt out with a
  `.claude-trunk-guard-allow` file at its worktree root.

## Branch Naming

- Default: kebab-case descriptive names (e.g., `add-user-auth`, `fix-login-bug`)
- Always check the project's CLAUDE.md or AGENTS.md for project-specific conventions before creating branches — project config overrides this default

## Rules

- Never use `git -C`. Agents are always launched inside the target repo or worktree, so plain `git` commands already operate on the correct repo. This applies even in bare-repo + worktree layouts where the worktree is a subdirectory of a non-repo parent.

## Commits

- Concise messages focused on "why" not "what"
- Follow existing commit style in the repo (check `git log --oneline -10`)
