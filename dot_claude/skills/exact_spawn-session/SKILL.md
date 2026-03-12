---
allowed-tools:
  - Bash(~/.claude/skills/spawn/spawn-tmux.sh:*)
  - Bash(~/.claude/skills/spawn/setup-worktree.sh:*)
  - Bash(~/.claude/skills/spawn/write-prompt.sh:*)
  - Bash(echo $TMUX:*)
  - Bash(tmux list-sessions*)
---

# Spawn Tmux Session

Forces a **tmux session** instead of the default window behavior.

Read and follow the instructions in `~/.claude/skills/spawn/SKILL.md` with these overrides:

- **Always use `--session`** instead of `--window` in step 5
- In the confirmation (step 6), tell the user how to attach: `tmux switch-client -t '=<name>'`
