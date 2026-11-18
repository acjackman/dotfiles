@~/.config/agents/core.md
@AGENTS.md

## Worktrees

A `WorktreeCreate` hook routes `isolation: "worktree"` through worktrunk automatically. Worktrees are created on branches named `claude-subagent/<session-id-prefix>`.

- Use `isolation: "worktree"` on Agent tool calls for isolated sub-agents — worktrunk manages the worktree
- Use `/worktree <branch-name>` when you need a **named branch** (e.g. for a PR or reuse across spawns)
- Use `/spawn` for full interactive Claude sessions in worktrees (with tmux)