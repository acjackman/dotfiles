# Chezmoi Dotfiles - Development Guide

## Overview

This repository manages dotfiles using [chezmoi](https://www.chezmoi.io/). Source files here are deployed to their target locations (`~/.config/`, `~/`, etc.).

**Golden rule: ALWAYS edit chezmoi source files, never deployed files.** Changes to deployed files are overwritten on next `chezmoi apply`.

## Quick Reference

- **Apply changes:** use the `/apply` skill (never `chezmoi apply --force`)
- **Preview changes:** `chezmoi diff`
- **File mapping:** `dot_` → `.`, `private_` → mode 0600, `executable_` → mode 0755
- **Find a config:** look in `dot_config/` (e.g., `~/.config/zsh/` → `dot_config/zsh/`)
- **Check for generators:** look for `run_onchange_*` scripts before editing config files
- **Removing/renaming files:** add old target path to `.chezmoiremove`

## Detailed Documentation

For in-depth guidance, see the `.docs/` directory:

- **`.docs/chezmoi.md`** — Chezmoi workflow, file name mapping, finding files, special files (`.chezmoiignore`, `.chezmoiremove`, `.chezmoiexternal`, etc.), and commands
- **`.docs/code-style.md`** — Shell, Python, Lua, and template conventions; functions vs scripts; chezmoi naming conventions
- **`.docs/git-workflows.md`** — Bare repository structure, worktrees, and worktrunk (`wt`) usage
- **`.docs/docs-guide.md`** — How this documentation is structured and maintained

## Directory-Specific Docs

Many directories contain their own `CLAUDE.md` with instructions specific to that tool/config (reload commands, generated file warnings, etc.). These auto-load when working in that directory.

## Key Conventions

- Prefer standalone scripts in `dot_local/bin/` over shell functions (unless the command must modify shell state)
- Use `run_onchange_` scripts for auto-reload on config changes
- Store reusable data in `.chezmoidata/` or `data/`
- Use chezmoi template syntax (`{{ .variable }}`) for platform-specific configs
