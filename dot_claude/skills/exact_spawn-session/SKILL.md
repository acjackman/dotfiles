---
allowed-tools:
  - Bash(~/.claude/skills/spawn/spawn-tmux.sh:*)
  - Bash(~/.claude/skills/spawn/setup-worktree.sh:*)
  - Bash(~/.claude/skills/spawn/write-prompt.sh:*)
  - Bash(echo $TMUX:*)
  - Bash(tmux list-sessions*)
---

# Spawn Tmux Session

Always spawns a **tmux session** — skip the task-size analysis.

Read and follow the instructions in `~/.claude/skills/spawn/SKILL.md` with these overrides:

- **Skip step 2** (task-size analysis) entirely
- **Always use `tmux new-session`** (the "Session" variant in step 8)
- For name conflict checks (step 7), only check `tmux list-sessions`
- In the confirmation (step 9), tell the user how to attach: `tmux switch-client -t '=<name>'`
