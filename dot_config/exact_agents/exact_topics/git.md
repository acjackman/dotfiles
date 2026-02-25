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

## Branch Naming

- Default: kebab-case descriptive names (e.g., `add-user-auth`, `fix-login-bug`)
- Always check the project's CLAUDE.md or AGENTS.md for project-specific conventions before creating branches — project config overrides this default

## Rules

- Never use `git -C`. Agents are always launched inside the target repo or worktree, so plain `git` commands already operate on the correct repo. This applies even in bare-repo + worktree layouts where the worktree is a subdirectory of a non-repo parent.

## Commits

- Concise messages focused on "why" not "what"
- Follow existing commit style in the repo (check `git log --oneline -10`)
