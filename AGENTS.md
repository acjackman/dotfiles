# Chezmoi Dotfiles - Development Guide

## IMPORTANT: Working with Chezmoi

**ALWAYS edit the chezmoi source files, not the deployed files.**

Chezmoi manages dotfiles by keeping source files in `~/.local/share/chezmoi/` and deploying them to their target locations (e.g., `~/.config/`, `~/`, etc.).

### Critical Workflow

1. **Edit source files** in `~/.local/share/chezmoi/`
   - Example: Edit `~/.local/share/chezmoi/dot_config/zsh/zshenv.zsh`
   - NOT: `~/.config/zsh/zshenv.zsh` (this will be overwritten)

2. **Apply changes** with `chezmoi apply`
   - This deploys your changes to the target locations
   - Preview first with `chezmoi diff`

3. **Verify** the deployed file has your changes

### Why This Matters

If you edit deployed files directly (e.g., `~/.config/zsh/zshenv.zsh`), your changes will be lost the next time `chezmoi apply` runs. Always edit the source in the chezmoi directory to make changes persistent.

### File Name Mapping

- `dot_` prefix → `.` (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_` prefix → file mode 0600
- `executable_` prefix → file mode 0755
- Path separators: `~/.local/share/chezmoi/dot_config/zsh/` → `~/.config/zsh/`

## Commands

### Chezmoi Management

- Apply changes: `chezmoi apply`
- Preview changes: `chezmoi diff`
- Check status: `chezmoi status`
- Edit file: `chezmoi edit <file>`
- Update from remote: `chezmoi update`
- Re-run scripts: `chezmoi apply --force`

### Testing & Validation

- Test shell config: `zsh -n ~/.zshrc` (syntax check)
- Test Python scripts: `python3 -m py_compile <file>`
- Validate TOML: `chezmoi execute-template < <file>.tmpl`

## Code Style

### Shell Scripts (Bash/Zsh)

- Use `#!/usr/bin/env zsh` or `#!/usr/bin/env bash` for portability
- Use `#!/bin/sh` for POSIX-compliant scripts
- No comments unless documenting complex logic
- Prefer `[[ ]]` over `[ ]` in bash/zsh

### Python

- Use type hints (from `typing` import)
- Prefer `pathlib.Path` over string paths
- Use `tomllib` (3.11+) or `tomli` for TOML parsing
- Follow existing patterns: see `dot_config/leader-key/run_onchange_after_generate_config.py.tmpl`

### Lua (Neovim)

- Follow LazyVim conventions
- Use `vim.opt` for options, `vim.g` for globals
- Keep plugin configs in `lua/exact_plugins/`

### Templates

- Use chezmoi template syntax: `{{ .variable }}`
- Conditional blocks: `{{ if condition }}...{{ end }}`
- Access data with `.chezmoi.os`, `.chezmoi.homeDir`, etc.

## Conventions

- Prefix files with `dot_` for dotfiles (e.g., `dot_zshrc` → `~/.zshrc`)
- Use `run_onchange_` for scripts that run when file changes
- Use `run_once_` for one-time setup scripts
- Use `executable_` prefix for executable files
- Use `symlink_` for symlinks
- Use `private_` for sensitive files (mode 0600)
- Store reusable data in `.chezmoidata/` or `data/`
