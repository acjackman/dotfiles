---
allowed-tools:
  - Bash(tmux new-window:*)
  - Bash(echo $TMUX:*)
  - Bash(tmux list-windows:*)
  - Bash(/opt/homebrew/bin/wt switch:*)
  - Bash(/opt/homebrew/bin/wt list:*)
  - Bash(mkdir:*)
---

# Spawn Tmux Window

Always spawns a **tmux window** — skip the task-size analysis.

Read and follow the instructions in `~/.claude/commands/spawn/SKILL.md` with these overrides:

- **Skip step 2** (task-size analysis) entirely
- **Always use `tmux new-window`** (the "Window" variant in step 8)
- For name conflict checks (step 7), only check `tmux list-windows`
- In the confirmation (step 9), tell the user how to switch: `tmux select-window -t <name>`
