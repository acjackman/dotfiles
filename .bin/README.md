# Chezmoi Command Aliases

Quick aliases for common chezmoi commands. Use with Claude Code's `!` prefix.

## Available Commands

- `,,a [args]` - `chezmoi apply` - Apply changes to target locations
- `,,d [args]` - `chezmoi diff` - Preview changes before applying
- `,,s [args]` - `chezmoi status` - Show status of managed files
- `,,u [args]` - `chezmoi update` - Update from remote repo

## Usage Examples

```bash
# Preview changes
!,,d

# Apply all changes
!,,a

# Check status
!,,s

# Update from remote
!,,u
```

## Setup

These scripts are added to PATH via `.mise.toml` in the repo root.
