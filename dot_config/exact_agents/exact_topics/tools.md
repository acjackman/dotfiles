# CLI Tools

Prefer modern tools for interactive and exploratory work. Standard tools are fine in scripts and CI.

## Search & Navigation

| Task | Tool | Notes |
|------|------|-------|
| Content search | `/safe-rg` | **Never** run `grep` or `rg` directly via Bash |
| File finding | `/safe-fd` | **Never** run `find` or `fd` directly via Bash |
| Find + search | `/safe-fd ... --grep -- <pattern>` | Replaces `find -exec grep` |
| File listing | `eza --group-directories-first` | Prefer over `ls` |
| Directory trees | `tre --limit 3` | Prefer over `tree` |

## Development

| Tool | Purpose |
|------|---------|
| `mise` | Runtime and task management (see `mise.md`) |
| `gh` | GitHub CLI — use for all GitHub operations |
| `lazygit` | Git TUI — available for interactive git work |
| `worktrunk` (`wt`) | Git worktree management (see `git.md`) |
