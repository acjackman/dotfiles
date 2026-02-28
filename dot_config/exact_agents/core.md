# Development Preferences

## Platform

- macOS, zsh, Homebrew
- `mise` for runtime and task management (see `topics/mise.md`)

## Tools

- Prefer modern CLI tools for interactive/exploratory work: `rg` over `grep`, `fd` over `find`, `eza` over `ls`
- Standard tools are fine in scripts and CI
- See `topics/tools.md` for the full catalog

## Git

- Bare repo + worktree layout, managed by `worktrunk` (`wt`)
- Default branch naming: kebab-case (e.g., `add-user-auth`, `fix-login-bug`)
- Project-level config can override — check the project's CLAUDE.md or AGENTS.md first
- **Worktree-aware searching**: Always scope searches to the worktree, not the full repo
  - Worktree root: `git rev-parse --show-toplevel`
  - Repo (bare) root: `git rev-parse --git-common-dir` (resolves to `.bare/`)
  - The working directory is typically already the worktree root — just search `.` or `$PWD`
- See `topics/git.md` for worktree workflows and conventions

## Testing

- Prefer TDD red/green cycle
- Test critical paths and edge cases; be pragmatic about glue code and obvious wrappers
- Ask before adding test infrastructure to a project that doesn't have it
- See `topics/workflow.md` for PR and CI patterns

## Progressive Disclosure

For detailed guidance on specific areas, see `~/.config/agents/topics/`:
- `git.md` — worktrees, branching, commits
- `tools.md` — CLI tool catalog and usage
- `mise.md` — runtimes, tasks, local config
- `workflow.md` — PRs, testing, CI
- `shell.md` — shell scripting conventions
