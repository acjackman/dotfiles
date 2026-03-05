---
allowed-tools:
  - Bash(~/.claude/skills/spawn/spawn-tmux.sh:*)
  - Bash(~/.claude/skills/spawn/setup-worktree.sh:*)
  - Bash(~/.claude/skills/spawn/write-prompt.sh:*)
  - Bash(echo $TMUX:*)
  - Bash(tmux list-windows*)
---

# Spawn Tmux Window

Always spawns a **tmux window** — skip the task-size analysis.

Read and follow the instructions in `~/.claude/skills/spawn/SKILL.md` with these overrides:

- **Skip step 2** (task-size analysis) entirely
- **Always use `tmux new-window`** (the "Window" variant in step 8)
- For name conflict checks (step 7), only check `tmux list-windows`
- In the confirmation (step 9), tell the user how to switch: `tmux select-window -t '=<name>'`
