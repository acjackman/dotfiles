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
- **`.docs/chezmoi-worktrees.md`** — How chezmoi interacts with git worktrees; applying from non-default worktrees
- **`.docs/docs-guide.md`** — How this documentation is structured and maintained

## Directory-Specific Docs

Many directories contain their own `CLAUDE.md` with instructions specific to that tool/config (reload commands, generated file warnings, etc.). These auto-load when working in that directory.

### Configs with Special Apply Instructions

Some configs require extra steps or alternative apply methods (especially from worktrees). Always check the directory `CLAUDE.md` before applying:

- **`data/karabiner/`** — Run `goku` directly instead of `chezmoi apply`
- **`dot_config/nvim/`** — Run `nvim --headless "+Lazy! restore" +qa` directly
- **`private_Library/.../Cursor/User/`** — Install extensions via `cursor --install-extension` directly
- **`data/mise/`** — Run `mise upgrade` directly

## Claude Code Skills

Skills (slash commands like `/spawn`, `/commit`, `/apply`) are defined in `dot_claude/skills/`. Each skill directory contains a `SKILL.md` and optional helper scripts. These deploy to `~/.claude/skills/` via chezmoi.

**Always edit the chezmoi source in `dot_claude/skills/`, not the deployed files in `~/.claude/skills/`.**

## Doctor Scripts

`,doctor-*` scripts in `dot_local/bin/` apply common fixes for a specific subsystem. The comma prefix follows the convention used by other user-facing utility commands in this repo (sorts early in tab-completion, no clash with system binaries).

**Naming:** `,doctor-<subsystem>` — e.g. `,doctor-mise`.

**Contract:**

- **Idempotent** — safe to run unconditionally. Re-running on a healthy system should be a no-op.
- **No required arguments** for the common case. Flags are fine for opt-in behavior (e.g. `--dry-run`).
- **Exit 0 on success**, non-zero only on real failure the user must act on.
- **Self-describing** — print what's being fixed as it runs, so the user can tell which check tripped.

**Helpers** (the actual fix logic) live alongside in `dot_local/bin/` without the `,` prefix, so doctors stay thin wrappers and helpers can be reused.

**Current scripts:**

- **`,doctor-mise`** — re-runs each mise tool's inline `postinstall` via the `mise-post-install` helper. Workaround for [mise #6933](https://github.com/jdx/mise/discussions/6933), where `mise upgrade` skips per-tool postinstall hooks for asdf-backed tools (most visible with gcloud losing `gke-gcloud-auth-plugin` after upgrade).
- **`,doctor-worktrunk`** — scans bare worktree repos under `~/dev/*/*` and ensures each carries the worktrunk `.config/mise.local.toml` (`WORKTRUNK_WORKTREE_PATH = "../{{ branch | sanitize }}"`, `{% raw %}`-guarded) that the `,gr-*` helpers install, then `mise trust`s it. Applies fixes by default; `--dry-run` to preview, `--base DIR` to scan elsewhere.

## Key Conventions

- Prefer standalone scripts in `dot_local/bin/` over shell functions (unless the command must modify shell state)
- Use `run_onchange_` scripts for auto-reload on config changes
- Store reusable data in `.chezmoidata/` or `data/`
- Use chezmoi template syntax (`{{ .variable }}`) for platform-specific configs
