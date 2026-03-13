---
description: Search file contents using ripgrep. Use instead of `grep` or `rg` when you need to search file contents by pattern via Bash.
allowed-tools:
  - Bash(bash ~/.claude/skills/safe-rg/safe-rg.sh:*)
---

# Safe rg

Read-only content searcher that wraps `rg`.

## Usage

```bash
bash ~/.claude/skills/safe-rg/safe-rg.sh [rg args...]
```

All standard `rg` arguments are supported.

## Examples

```bash
# Search for a pattern
bash ~/.claude/skills/safe-rg/safe-rg.sh 'TODO' src/

# Search with file type filter
bash ~/.claude/skills/safe-rg/safe-rg.sh -t py 'import logging'

# Search with context lines
bash ~/.claude/skills/safe-rg/safe-rg.sh -C 3 'handleError'

# Case-insensitive search
bash ~/.claude/skills/safe-rg/safe-rg.sh -i 'config_path'

# List files with matches only
bash ~/.claude/skills/safe-rg/safe-rg.sh -l 'deprecated'
```
