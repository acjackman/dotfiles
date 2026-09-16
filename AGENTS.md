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
- **`,doctor-herdr`** — keeps the running herdr server in step with the installed binary. One root cause (`brew upgrade` swaps the binary while the old server keeps running), three symptoms: **stale keybindings** (the old server serves an old `[[keys.command]]` table), **stale binary** (still protocol-compatible, but executing the old code), and **protocol mismatch** (every plugin and all agent surface control break at once). The first two are fixed by default; the mismatch is not. Stale-binary adoption uses `herdr server live-handoff --import-exe`, which passes live pane PTYs to a replacement server so **pane processes survive** — undocumented, so the script gates on `.server.capabilities.live_handoff` from `herdr status --json` and degrades to report-only if that disappears. **Exception to the "applies fixes by default" rule:** a mismatch can only be cleared by `herdr server stop`, which kills every pane process including running agents, so it reports by default and restarts only under `--restart`, exiting 1 until then. The catch worth knowing: handoff is negotiated *through* the socket, so once the protocol has drifted the rescue itself is refused — the gap you need to cross is the gap that blocks crossing it. The fix is timing, which is what `--freshen` is for: a silent, restart-free, no-op-unless-it-acts mode driven every 30 minutes by the `com.acjackman.herdr-freshen` LaunchAgent (`private_Library/LaunchAgents/`). It is a launchd timer rather than a shell hook because every shell here starts inside a herdr pane, and asking a server to transfer its PTYs from inside a pane it is mid-way through creating is the one moment handoff should not be attempted.
- **`,doctor-worktrunk`** — scans bare worktree repos under `~/dev/*/*` and ensures each carries the worktrunk `.config/mise.local.toml` (`WORKTRUNK_WORKTREE_PATH = "../{{ branch | sanitize }}"`, `{% raw %}`-guarded) that the `,gr-*` helpers install, then `mise trust`s it. Applies fixes by default; `--dry-run` to preview, `--base DIR` to scan elsewhere.
- **`,doctor-prune`** — reclaims disk space via the `prune-caches` helper, in four tiers: (1) caches that regenerate for free (Homebrew downloads, uv, Go build/module cache, unused mise tool versions, pip/poetry/node-gyp), (2) logs over `--log-threshold` (default 512M), (3) expensive to rebuild (container images, HuggingFace models, Puppeteer browsers, Claude VM bundles), and (4) report-only — worktrees, Downloads, browser caches. **Exception to the "applies fixes by default" rule** (like `,doctor-herdr`): it reports by default and prunes only under `--apply` (tier 1+2) or `--all` (adds tier 3), because re-downloading tens of GB is a slow mistake to make by reflex. Tier 4 is never pruned here — worktrees hold uncommitted work and `wt remove` refuses a dirty tree, so that call belongs to `,g-cleanup-wt`; browser caches rebuild within a day. Logs are truncated with `: >` rather than `rm` so a running process's open fd keeps working instead of writing to a ghost inode that never frees space.
- **`,doctor-zsh`** — rebuilds the zsh completion dump via the `,zsh-cleanup-completions` helper. `compinit` runs with `-C` (trust the dump, rebuild only when missing or older than a day) because three uncached rebuilds per shell were costing ~1 s per new pane, so a freshly installed tool otherwise waits up to a day for Tab completion. The same helper runs from topgrade (`Rebuild Zsh Completions`) and from the chezmoi `run_onchange` hooks for `dot_config/zsh/` and `data/mise/`.
- **`,doctor-tuna`** — warns when the Tuna config fragments (`.chezmoitemplates/tuna/`) have gone stale. Tuna rewrites `~/.config/tuna/config.toml` from in-memory state on quit, on UI edits, and after a version migration, so every rewrite puts the chezmoi source behind the app and the next apply silently reverts it — which across a schema bump has failed Tuna's migration and silently dropped every leaf binding. Checks two independent signals: installed version vs `tuna_synced_version` in `.chezmoidata.yaml` (the early warning; the version moves before Tuna next saves) and deployed content vs what chezmoi would write. **Exception to the "applies fixes by default" rule:** it reports and exits 1 without fixing, because re-syncing means deciding per hunk which side is authoritative and splitting the result across three fragments. The non-lossy half of the guard is `dot_config/tuna/run_before_backup-tuna-config.sh.tmpl`, which snapshots the deployed file to `~/.local/state/tuna-config-backups/` before any apply can overwrite it (one backup per distinct content).

## Key Conventions

- Prefer standalone scripts in `dot_local/bin/` over shell functions (unless the command must modify shell state)
- Use `run_onchange_` scripts for auto-reload on config changes
- Store reusable data in `.chezmoidata/` or `data/`
- Use chezmoi template syntax (`{{ .variable }}`) for platform-specific configs
