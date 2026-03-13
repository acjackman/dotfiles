---
description: Find files by name/pattern using fd, with optional --grep to search file contents. Use instead of `find` or `fd` via Bash. Supports --grep to pipe results through safe-rg (replaces find+exec grep pattern).
allowed-tools:
  - Bash(bash ~/.claude/skills/safe-fd/safe-fd.sh:*)
---

# Safe fd

Read-only file finder that wraps `fd`. The `--exec` and `--exec-batch` flags are blocked for safety. Use `--grep` to search within found files instead.

## Usage

```bash
# Find files
bash ~/.claude/skills/safe-fd/safe-fd.sh [fd args...]

# Find files, then search their contents
bash ~/.claude/skills/safe-fd/safe-fd.sh [fd args...] --grep -- <rg args...>
```

All standard `fd` arguments are supported **except** `-x`/`--exec` and `-X`/`--exec-batch`, which are rejected.

## --grep flag

Use `--grep` to pipe fd results through safe-rg. Everything after `--grep` is passed as arguments to safe-rg. This is the safe alternative to `fd --exec grep`.

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

# Find .ts files, then grep for "useState"
bash ~/.claude/skills/safe-fd/safe-fd.sh -e ts --grep -- useState

# Find files in src/, grep for a pattern
bash ~/.claude/skills/safe-fd/safe-fd.sh . src/ --grep -- 'import.*React'

# Find config files, search for a specific key
bash ~/.claude/skills/safe-fd/safe-fd.sh -e yaml -e yml . config/ --grep -- 'database_url'
```
