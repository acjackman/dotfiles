---
allowed-tools:
  - Bash(~/.claude/commands/spawn/spawn-tmux.sh:*)
  - Bash(~/.claude/commands/spawn/setup-worktree.sh:*)
  - Bash(echo $TMUX:*)
  - Bash(tmux list-sessions:*)
---

# Spawn Tmux Session

Always spawns a **tmux session** — skip the task-size analysis.

Read and follow the instructions in `~/.claude/commands/spawn/SKILL.md` with these overrides:

- **Skip step 2** (task-size analysis) entirely
- **Always use `tmux new-session`** (the "Session" variant in step 8)
- For name conflict checks (step 7), only check `tmux list-sessions`
- In the confirmation (step 9), tell the user how to attach: `tmux switch-client -t <name>`
