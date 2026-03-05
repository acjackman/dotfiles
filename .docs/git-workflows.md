# Git Workflows

## Bare Repositories with Worktrees

When working with bare git repositories, I prefer a specific directory structure where worktrees are siblings to the `.bare` directory.

**Preferred Structure:**
```
~/dev/project-name/
  .bare/              # The bare repository
  main/               # Worktree for main branch
  feature-branch/     # Worktree for feature branch
  pr-123/             # Worktree for PR branch
  bugfix-name/        # Worktree for bugfix branch
  ...
```

**Key points:**
- The bare repository lives in `.bare/`
- Each branch gets its own worktree directory as a sibling to `.bare/`
- Worktree names typically match branch names (with `/` replaced by `-`)
- This allows easy navigation and multiple branches checked out simultaneously
- I use `worktrunk` (`wt`) to manage these git worktrees and branches

## Worktrunk (`wt`) Usage

Worktrunk is a Git worktree management CLI designed for parallel AI agent workflows. It simplifies managing multiple worktrees by abstracting Git's native worktree commands.

**Common Commands:**
```bash
wt switch --create feature    # Create worktree and branch
wt switch feature             # Switch to existing worktree
wt list                       # Show all worktrees with status
wt remove                     # Remove worktree; delete branch if merged
wt merge                      # Merge current branch into target
```

**With Claude Code:**
```bash
wt switch -x claude -c feature-name -- 'Task description'
# Creates branch, worktree, and launches Claude in one command
```

**Resources:**
- Docs: https://worktrunk.dev
- GitHub: https://github.com/max-sixty/worktrunk
