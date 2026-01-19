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

### Special Files

Chezmoi recognizes several special files that control its behavior. These are processed in a specific order:

#### `.chezmoiignore`

Specifies files/directories to exclude from management. Patterns match against **target paths** (not source paths).

- Supports glob patterns via `doublestar.Match` (e.g., `*.txt`, `backups/**`)
- Lines starting with `#` are comments (mid-line `#` needs preceding whitespace)
- Prefix patterns with `!` to negate (exclusions take priority)
- **Always interpreted as a template** (even without `.tmpl` extension)
- Files in subdirectories apply only to that subdirectory

Example:
```
README.md
*.log
backups/**

# OS-specific ignores
{{- if ne .chezmoi.os "darwin" }}
.config/macos-only/
{{- end }}
```

#### `.chezmoiremove`

Specifies files to **delete** from the target during `chezmoi apply`. Use for cleaning up deprecated configs.

- **Always interpreted as a template** (even without `.tmpl` extension)
- Patterns prefixed with `!` or listed in `.chezmoiignore` are never removed
- Use `.chezmoiignore` to prevent files from being created; use `.chezmoiremove` to delete existing files

Example:
```
# Remove old config locations
.old-bashrc
.config/deprecated-app/
```

#### `.chezmoiexternal.$FORMAT`

Includes external files/archives from URLs as if they were in the source state. Supports TOML, YAML, or JSON.

Types:
- `file` — Download a single file
- `archive` — Extract archive contents
- `archive-file` — Extract specific file from archive
- `git-repo` — Clone/pull a git repository

Key fields: `type`, `url`, `refreshPeriod`, `exact`, `executable`, `stripComponents`

Example (TOML):
```toml
[".vim/autoload/plug.vim"]
    type = "file"
    url = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    refreshPeriod = "168h"
```

#### `.chezmoidata.$FORMAT`

Static data files (TOML, YAML, JSON) that are merged into the template data dictionary. Read in lexical order. **Cannot be templates** (loaded before template engine starts).

#### `.chezmoidata/` (Directory)

Same as `.chezmoidata.$FORMAT` but as a directory containing multiple data files. All files merge to the root of the data dictionary.

#### `.chezmoitemplates/`

Directory containing reusable templates. Templates here can be included in source files using `{{ template "name" . }}`.

#### `.chezmoiversion`

Contains a semantic version specifying the minimum chezmoi version required. Checked before operations proceed.

#### `.chezmoiroot`

If present, specifies a subdirectory (relative path) to use as the actual source state root. Read before all other files. All other special files must be moved into the new root.

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
