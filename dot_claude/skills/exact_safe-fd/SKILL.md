---
description: Find files by name/pattern using fd. Use instead of `find` or `fd` when you need to search for files by name, extension, or glob pattern via Bash.
allowed-tools:
  - Bash(bash ~/.claude/skills/safe-fd/safe-fd.sh:*)
---

# Safe fd

Read-only file finder that wraps `fd` with exec options blocked.

## Usage

```bash
bash ~/.claude/skills/safe-fd/safe-fd.sh [fd args...]
```

All standard `fd` arguments are supported **except** `-x`/`--exec` and `-X`/`--exec-batch`, which are rejected.

## Examples

```bash
# Find files by extension
bash ~/.claude/skills/safe-fd/safe-fd.sh -e ts

# Find files matching a pattern
bash ~/.claude/skills/safe-fd/safe-fd.sh 'component' src/

# Find directories only
bash ~/.claude/skills/safe-fd/safe-fd.sh -t d config

# Find hidden files
bash ~/.claude/skills/safe-fd/safe-fd.sh -H '.env'
```
