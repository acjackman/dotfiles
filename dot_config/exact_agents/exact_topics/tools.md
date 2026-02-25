# CLI Tools

Prefer modern tools for interactive and exploratory work. Standard tools are fine in scripts and CI.

## Search & Navigation

| Task | Tool | Notes |
|------|------|-------|
| Content search | `rg` (ripgrep) | Prefer over `grep` |
| File finding | `fd` | Prefer over `find` |
| File listing | `eza --group-directories-first` | Prefer over `ls` |
| Directory trees | `tre --limit 3` | Prefer over `tree` |

## Development

| Tool | Purpose |
|------|---------|
| `mise` | Runtime and task management (see `mise.md`) |
| `gh` | GitHub CLI — use for all GitHub operations |
| `lazygit` | Git TUI — available for interactive git work |
| `worktrunk` (`wt`) | Git worktree management (see `git.md`) |
