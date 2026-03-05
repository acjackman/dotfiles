# Code Style & Conventions

## Shell Scripts (Bash/Zsh)

- Use `#!/usr/bin/env zsh` or `#!/usr/bin/env bash` for portability
- Use `#!/bin/sh` for POSIX-compliant scripts
- No comments unless documenting complex logic
- Prefer `[[ ]]` over `[ ]` in bash/zsh

## Functions vs Scripts

Prefer standalone scripts in `dot_local/bin/` unless the command must modify the caller's shell state:
- **Working directory** — `cd`, `pushd`, `popd`
- **Environment variables** — `export`, `unset`
- **Shell execution context** — `eval`, `source`
- **Shell options** — `setopt`/`unsetopt` that persist after the command

If none of these apply, make it a script. Scripts are shell-agnostic, independently testable, and work in non-interactive contexts.

## Python

- Use type hints (from `typing` import)
- Prefer `pathlib.Path` over string paths
- Use `tomllib` (3.11+) or `tomli` for TOML parsing
- Follow existing patterns: see `dot_config/leader-key/run_onchange_after_generate_config.py.tmpl`

## Lua (Neovim)

- Follow LazyVim conventions
- Use `vim.opt` for options, `vim.g` for globals
- Keep plugin configs in `lua/exact_plugins/`

## Templates

- Use chezmoi template syntax: `{{ .variable }}`
- Conditional blocks: `{{ if condition }}...{{ end }}`
- Access data with `.chezmoi.os`, `.chezmoi.homeDir`, etc.

## Chezmoi Naming Conventions

- Prefix files with `dot_` for dotfiles (e.g., `dot_zshrc` → `~/.zshrc`)
- Use `run_onchange_` for scripts that run when file changes
- Use `run_once_` for one-time setup scripts
- Use `executable_` prefix for executable files
- Use `symlink_` for symlinks
- Use `private_` for sensitive files (mode 0600)
- Store reusable data in `.chezmoidata/` or `data/`
