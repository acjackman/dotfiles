@~/.config/agents/core.md
@AGENTS.md

## Worktrees

**Never use `isolation: "worktree"` on Task tool calls.** It creates worktrees in `.claude/worktrees/` instead of using worktrunk.

When a sub-agent needs an isolated worktree:

1. Use `/worktree <branch-name>` to create a worktrunk-managed worktree
2. Pass the returned worktree path in the Task prompt so the sub-agent works there

For full interactive Claude sessions in worktrees (with tmux), use `/spawn` instead.
