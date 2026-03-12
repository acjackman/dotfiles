---
allowed-tools:
  - Bash(~/.claude/skills/spawn/spawn-tmux.sh:*)
  - Bash(~/.claude/skills/spawn/setup-worktree.sh:*)
  - Bash(~/.claude/skills/spawn/write-prompt.sh:*)
  - Bash(echo $TMUX:*)
  - Bash(tmux list-windows*)
---

# Spawn Tmux Window

This skill is equivalent to `spawn` — the base spawn skill now always creates tmux windows.

Read and follow the instructions in `~/.claude/skills/spawn/SKILL.md`.
