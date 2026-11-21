# Chezmoi Dotfiles - Development Guide

## Overview

This repository manages dotfiles using [chezmoi](https://www.chezmoi.io/). Source files here are deployed to their target locations (`~/.config/`, `~/`, etc.).

**Golden rule: ALWAYS edit chezmoi source files, never deployed files.** Changes to deployed files are overwritten on next `chezmoi apply`.

## Repo Layout

`.chezmoiroot` points chezmoi at `home/`, so **only `home/` is the chezmoi source**. Everything at the repo root (`AGENTS.md`, `README.md`, `docs/`, `.github/`, `tests/`, `data/`, `bootstrap.sh`, `.claude/`, `.mise.toml`) is repo tooling and never deploys. Special files (`.chezmoiignore`, `.chezmoiremove`, `.chezmoidata/`, `.chezmoitemplates/`, `.chezmoiexternal.toml`, `.chezmoi.toml.tmpl`, `.chezmoiversion`) live in `home/`.

**Source paths in these docs are written from the repo root (`home/dot_config/...`).** `data/` stays at the repo root; templates reach it with `{{ dir .chezmoi.sourceDir }}/data/...` (and `include "../data/..."`), because `.chezmoi.sourceDir` is `home/`. Per-directory `CLAUDE.md` files inside `home/` stay in `home/.chezmoiignore` (`**/CLAUDE.md`); the paths they mention (`dot_config/...`, `.chezmoitemplates/...`) are relative to `home/`.

## Quick Reference

- **Apply changes:** use the `/apply` skill (never `chezmoi apply --force`)
- **Preview changes:** `chezmoi diff`
- **File mapping:** `dot_` → `.`, `private_` → mode 0600, `executable_` → mode 0755
- **Find a config:** look in `home/dot_config/` (e.g., `~/.config/zsh/` → `home/dot_config/zsh/`)
- **Check for generators:** look for `run_onchange_*` scripts before editing config files
- **Removing/renaming files:** add old target path to `home/.chezmoiremove`

## Detailed Documentation

For in-depth guidance, see the `docs/` directory:

- **`docs/chezmoi.md`** — Chezmoi workflow, file name mapping, finding files, special files (`home/.chezmoiignore`, `home/.chezmoiremove`, `.chezmoiexternal`, etc.), and commands
- **`docs/code-style.md`** — Shell, Python, Lua, and template conventions; functions vs scripts; chezmoi naming conventions
- **`docs/git-workflows.md`** — Bare repository structure, worktrees, and worktrunk (`wt`) usage
- **`docs/chezmoi-worktrees.md`** — How chezmoi interacts with git worktrees; applying from non-default worktrees
- **`docs/docs-guide.md`** — How this documentation is structured and maintained

## Directory-Specific Docs

Many directories contain their own `CLAUDE.md` with instructions specific to that tool/config (reload commands, generated file warnings, etc.). These auto-load when working in that directory.

### Configs with Special Apply Instructions

Some configs require extra steps or alternative apply methods (especially from worktrees). Always check the directory `CLAUDE.md` before applying:

- **`data/karabiner/`** — Run `goku` directly instead of `chezmoi apply`
- **`home/dot_config/nvim/`** — Run `nvim --headless "+Lazy! restore" +qa` directly
- **`home/private_Library/.../Cursor/User/`** — Install extensions via `cursor --install-extension` directly
- **`data/mise/`** — Run `mise upgrade` directly

## Claude Code Skills

Skills (slash commands like `/spawn`, `/apply`) are defined in `home/dot_claude/skills/`. Each skill directory contains a `SKILL.md` and optional helper scripts. These deploy to `~/.claude/skills/` via chezmoi.

**Always edit the chezmoi source in `home/dot_claude/skills/`, not the deployed files in `~/.claude/skills/`.**

**Mods** (Claude Code plugins with a hooks module, e.g. `/bye`) live in `home/dot_claude/mods/<name>/` and deploy to `~/.claude/mods/<name>/`. The settings generator puts every mod dir in `env.CLAUDE_CODE_PLUGIN_DIRS` of each config dir's `settings.json`, so adding a folder there is all it takes to load a mod everywhere.

**Third-party skills** (e.g. `t3dotgg/tstack`, `mattpocock/skills`) are listed in `home/.chezmoidata/agent-skills.yaml` with one pinned commit per repo. `home/.chezmoiexternal.toml` extracts each into `~/.config/agents/skills/<name>` (an exact dir, so unlisted skills are removed); `~/.agents/skills` symlinks there for Codex and other agents, and `home/dot_claude/run_after_link-agent-skills.sh.tmpl` links them into `~/.claude/skills`. Add, remove or bump skills in the data file — never with `npx skills add -g`, which writes into the managed dir and is wiped on apply. Bump a repo as a whole after reviewing the upstream diff, since skills in a suite call each other.

## Claude Code profiles

A profile is a config dir under `~/.config/claude/profiles/<name>/`, selected with `CLAUDE_CONFIG_DIR`. The dirs aren't chezmoi-managed; every generator in `home/dot_claude/` (settings, plugins, MCP servers, CLAUDE.md, skills) and the Rex/herdr/Plannotator scripts loop over whichever exist, so a new dir is picked up on the next apply. Each has its own login, sessions and history.

- **`~/.claude`**: no session uses it on moov machines, where `data/mise/moov.toml` sets `CLAUDE_CONFIG_DIR` to `moov-api` globally. It stays as the shared source the profiles link to (skills, mods, statusline), and keeps `forceLoginMethod: console` so anything that still lands there bills to the API, not the Team seat.
- **`personal`**: personal subscription. Personal repos set it in `.mise.local.toml`.
- **`moov-api`**: the Moov API org (`forceLoginMethod: console`). The default on moov machines; `claude-api` pins it to a repo.
- **`moov-team`**: the Moov Claude Team seat (`forceLoginMethod: claudeai`), launched with `claude-team`. Keeping everyday work on the API saves the Team credit balance for Claude Duet.

`forceLoginOrgUUID` pins a profile's sign-in to one organization (`personal` and `moov-team` here). The UUIDs live in the machine-local chezmoi config as `[data.claude_org_uuids]` (profile name → UUID), which `home/.chezmoi.toml.tmpl` carries across `chezmoi init`; they stay out of this public repo.

`claude-team` and `claude-api` wrap `claude-profile <name> [claude args]`, which starts claude on the profile and, inside a git repo, writes `CLAUDE_CONFIG_DIR` to the worktree root's local mise config (whichever file already sets it, else the existing local file mise ranks highest, else a new `.mise.local.toml`), so plain `claude` there stays on that profile.

Plugins come from `home/dot_claude/plugins.json` `.extras` for the profile's name, and for its prefix before a dash (`moov-team` and `moov-api` get `moov`). `moov-*` profiles also get the Honeycomb OTEL env and `auto` permission mode in `claude-yolo`. Hand-edited settings such as `autoMode` aren't generated, so a new profile starts with a copy of them from `~/.claude/settings.json`.

## Doctor Scripts

`,doctor-*` scripts in `home/dot_local/bin/` apply common fixes for a specific subsystem. The comma prefix follows the convention used by other user-facing utility commands in this repo (sorts early in tab-completion, no clash with system binaries).

**Naming:** `,doctor-<subsystem>` — e.g. `,doctor-mise`.

**Contract:**

- **Idempotent** — safe to run unconditionally. Re-running on a healthy system should be a no-op.
- **No required arguments** for the common case. Flags are fine for opt-in behavior (e.g. `--dry-run`).
- **Exit 0 on success**, non-zero only on real failure the user must act on.
- **Self-describing** — print what's being fixed as it runs, so the user can tell which check tripped.

**Helpers** (the actual fix logic) live alongside in `home/dot_local/bin/` without the `,` prefix, so doctors stay thin wrappers and helpers can be reused.

**Current scripts:**

- **`,doctor-dotfiles`** — reports anything that leaves `~` out of step with the chezmoi source: (1) **replaced copies** waiting for review in `~/.local/state/dotfiles/replaced/<subsystem>/`, (2) **drift** from `chezmoi status -x scripts`, (3) **source repo** uncommitted changes and commits ahead of or behind upstream (as of the last fetch), (4) **`chezmoi doctor`** warnings, minus the dirty-tree checks (3 covers them) and the newer-version notice (topgrade's job). **Report-only, exits 1 on any finding**, since each needs a judgement call. Never call it from a chezmoi script: chezmoi holds its state lock during apply.
- **`,doctor-mise`** — re-runs each mise tool's inline `postinstall` via the `mise-post-install` helper. Workaround for [mise #6933](https://github.com/jdx/mise/discussions/6933), where `mise upgrade` skips per-tool postinstall hooks for asdf-backed tools (most visible with gcloud losing `gke-gcloud-auth-plugin` after upgrade).
- **`,doctor-herdr`** — keeps the running herdr server in step with the installed binary. One root cause (an upgrade swaps the binary while the old server keeps running; `herdr update --handoff`, which topgrade starts through the on-demand `com.acjackman.herdr-update` LaunchAgent because herdr refuses to update from inside a pane, avoids it; a plain `herdr update` doesn't), three symptoms: **stale keybindings** (the old server serves an old `[[keys.command]]` table), **stale binary** (still protocol-compatible, but executing the old code), and **protocol mismatch** (every plugin and all agent surface control break at once). The first two are fixed by default; the mismatch is not. Stale-binary adoption uses `herdr server live-handoff --import-exe`, which passes live pane PTYs to a replacement server so **pane processes survive** — undocumented, so the script gates on `.server.capabilities.live_handoff` from `herdr status --json` and degrades to report-only if that disappears. **Exception to the "applies fixes by default" rule:** a mismatch can only be cleared by `herdr server stop`, which kills every pane process including running agents, so it reports by default and restarts only under `--restart`, exiting 1 until then. `--force-restart` stops the server even when healthy — for problems a fresh server clears but the doctor can't detect, like a server that inherited launchd's bare PATH (a live handoff carries the environment across, so it can't fix that). The catch worth knowing: handoff is negotiated *through* the socket, so once the protocol has drifted the rescue itself is refused — the gap you need to cross is the gap that blocks crossing it. The fix is timing, which is what `--freshen` is for: a silent, restart-free, no-op-unless-it-acts mode driven every 30 minutes by the `com.acjackman.herdr-freshen` LaunchAgent (`home/private_Library/LaunchAgents/`). It is a launchd timer rather than a shell hook because every shell here starts inside a herdr pane, and asking a server to transfer its PTYs from inside a pane it is mid-way through creating is the one moment handoff should not be attempted.
- **`,doctor-worktrunk`** — scans bare worktree repos under `~/dev/*/*` and ensures each carries the worktrunk `.config/mise.local.toml` (`WORKTRUNK_WORKTREE_PATH = "../{{ branch | sanitize }}"`, `{% raw %}`-guarded) that the `,gr-*` helpers install, then `mise trust`s it. Applies fixes by default; `--dry-run` to preview, `--base DIR` to scan elsewhere.
- **`,doctor-prune`** — reclaims disk space via the `prune-caches` helper, in four tiers: (1) caches that regenerate for free (Homebrew downloads, uv, Go build/module cache, unused mise tool versions, pip/poetry/node-gyp), (2) logs over `--log-threshold` (default 512M), (3) expensive to rebuild (container images, HuggingFace models, Puppeteer browsers, Claude VM bundles), and (4) report-only — worktrees, Downloads, browser caches. **Exception to the "applies fixes by default" rule** (like `,doctor-herdr`): it reports by default and prunes only under `--apply` (tier 1+2) or `--all` (adds tier 3), because re-downloading tens of GB is a slow mistake to make by reflex. Tier 4 is never pruned here — worktrees hold uncommitted work and `wt remove` refuses a dirty tree, so that call belongs to `,g-cleanup-wt`; browser caches rebuild within a day. Logs are truncated with `: >` rather than `rm` so a running process's open fd keeps working instead of writing to a ghost inode that never frees space.
- **`,doctor-zsh`** — rebuilds the zsh completion dump via the `,zsh-cleanup-completions` helper. `compinit` runs with `-C` (trust the dump, rebuild only when missing or older than a day) because three uncached rebuilds per shell were costing ~1 s per new pane, so a freshly installed tool otherwise waits up to a day for Tab completion. The same helper runs from topgrade (`Rebuild Zsh Completions`) and from the chezmoi `run_onchange` hooks for `home/dot_config/zsh/` and `data/mise/`.
- **`,doctor-tuna`** — warns when the Tuna config fragments (`home/.chezmoitemplates/tuna/`) have gone stale. Tuna rewrites `~/.config/tuna/config.toml` from in-memory state on quit, on UI edits, and after a version migration, so every rewrite puts the chezmoi source behind the app and the next apply silently reverts it — which across a schema bump has failed Tuna's migration and silently dropped every leaf binding. Checks two independent signals: installed version vs `tuna_synced_version` in `home/.chezmoidata.yaml` (the early warning; the version moves before Tuna next saves) and deployed content vs what chezmoi would write. **Exception to the "applies fixes by default" rule:** it reports and exits 1 without fixing, because re-syncing means deciding per hunk which side is authoritative and splitting the result across three fragments. The non-lossy half of the guard is `home/dot_config/tuna/run_before_backup-tuna-config.sh.tmpl`, which snapshots the deployed file to `~/.local/state/dotfiles/replaced/tuna/` before any apply can overwrite it (one backup per distinct content).

**Replaced copies convention:** any script that overwrites or moves aside something chezmoi doesn't own (a generator rewriting a merged config, a pre-apply guard) saves the old version to `${XDG_STATE_HOME:-~/.local/state}/dotfiles/replaced/<subsystem>/` rather than a `.bak` beside the file. Copies wait there until reviewed and deleted. `run_after_zz-warn-replaced.sh` prints a one-line reminder on every apply while any exist. Current writers: agent-skills, tuna, sesh, rex (Shortcuts/shortcuts.json, which Rex rewrites from Settings > Keyboard), defaults (app-side setting changes, before chezmoi can overwrite them). (codex wrote them until its `config.toml` became a modify_ template; the old ones are in `replaced/codex/`.)

## App preferences (plist defaults)

App settings that live in a `defaults` domain are one TOML file per app (or per domain) in `home/dot_local/state/dotfiles/defaults/<app>.toml`, not `defaults write` scripts. (`home/dot_config/macos/run_onchange_darwin-defaults.sh.tmpl` stays a script: it has logic, dicts and `killall`s.) The file is `domain = "..."` plus a `[values]` table:

- **listed** `"key" = value`: managed, set by apply. Values: strings (`"…"` or `'…'`), bools, ints, floats, one-line arrays of those, `{ data = "<hex>" }` for raw bytes
- **`"key" = { unset = true }`**: managed, deleted by apply
- **not listed**: ignored (window frames, runtime toggles, app state)

Use `<app>.toml.tmpl` only for values that differ per machine; a template that renders empty means "not on this machine" (e.g. `keepingyouawake`, work only). Keep the rest of the app in a plain file (`cleanshotx.toml` + `cleanshotx-paths.toml.tmpl`): `chezmoi re-add` never writes into templates. Floats compare at 32-bit precision, because that's what `defaults write -float` stores.

The target `~/.local/state/dotfiles/defaults/<app>.toml` holds the **live** values, not the desired ones: `.chezmoi-hooks/defaults-sync.py snapshot` rewrites it from the plist before every chezmoi command (`hooks.read-source-state.pre`). So `chezmoi diff`/`status` show settings changed in the app, `chezmoi re-add <target>` takes them into the source, and `run_after_zz-apply-defaults.sh` pushes the deployed file into the plist. A setting changed in the app makes apply ask "has changed since chezmoi last wrote it?" like any edited file; without a TTY it stops there. Show the user `chezmoi diff` and let them choose re-add or overwrite. Never `--force`. The script is `zz-` because chezmoi ran an earlier-sorting `run_after_` script before writing the TOML beside it.

## Linear → worktree → Rex

Linear's "Work on issue → Custom script" runs `,linear-start` via `home/dot_linear/coding-tools.json.tmpl` (deploys to `~/.linear/coding-tools.json`). It resolves the repo, creates or reuses the worktree through `spawn-setup-worktree`, writes the issue prompt to `<worktree>/.tmp/linear-<ID>.md`, opens a Rex session (herdr workspace as fallback), and starts Claude. In refine mode (the default) it types a one-line prompt without submitting; `--mode ship` submits. Re-running for the same issue focuses the existing session.

- **Multiplexer choice:** `preferred-mux` prints the first usable of `$PREFERRED_MUX` (default `rex herdr tmux`). Rex is on trial; herdr and Ghostty stay installed, so `PREFERRED_MUX="herdr tmux"` switches every launcher back.

- **Repo resolution order:** `--repo`, `LINEAR_WORK_DIR` if it's inside a repo, picks remembered in `~/.local/state/linear-start/repos.toml`, the hand-written map `home/dot_config/linear-start/repos.toml` (`[projects]` beats `[teams]`), then an fzf picker. Linear runs the script with no TTY, so the picker re-runs the script inside a herdr pane.
- **State lives in XDG state:** `~/.local/state/linear-start/` holds `log.jsonl` (one line per run) and the remembered picks. Failures also go to `noti`.
- **`--dry-run`** prints the resolved repo, branch, label and launch command without creating anything.
- **CommandRouter** (`command-file-router`) handles `.command` files from Linear's built-in tools separately. It opens each one in a new Rex session (else herdr workspace, else tmux window), and never parses the file beyond its `cd` line.
- **`rex-open <label|session_id> [dir]`** shows a Rex session (creating it in `dir` if missing) and raises Rex; switching the app to the session needs Rex's Remote Control on. `herdr-reveal <workspace_id>` is the herdr equivalent. Both entry points use whichever matches the multiplexer.

## Plannotator Inbox

One Inbox server per machine, run by launchd (`com.acjackman.plannotator-inbox`); agents only connect to it. The binary is installed `--minimal`, so the installer never touches agent configs; connections live in source: the Claude plugin in `home/dot_claude/plugins.json`, Codex in `home/.chezmoitemplates/codex/40-mcp-servers.toml`.

- **Supervisor, not a plain job:** the Upgrade button and `inbox restart` replace the server with a *detached* process and exit 0, which launchd loses track of. The job runs `plannotator-inbox-supervise`, which adopts whichever Inbox is running and starts one only when none is. Stopping the job (`launchctl bootout`) leaves an adopted server running.
- **One data dir:** an existing `~/.plannotator` beats `XDG_DATA_HOME` for any process without `PLANNOTATOR_DATA_DIR`, and that process silently gets its own Inbox. Three layers keep everything on `~/.local/share/plannotator`: the export in `home/dot_config/shell/env.sh`, `launchctl setenv` from `com.acjackman.launchd-env` for GUI apps, and the managed symlink `~/.plannotator` → `~/.local/share/plannotator` for anything that still misses both (e.g. an agent started from an old herdr pane).
- **`PLANNOTATOR_INBOX_CONNECT=0`** in the plist: a foreground `plannotator inbox` otherwise writes MCP entries into every agent it finds, including chezmoi-managed configs. Set it on any manual foreground run too.
- **Links open in the Safari web app:** Finicky routes `localhost`/`127.0.0.1` on the Inbox port to `~/Applications/Plannotator.app` (Safari > File > Add to Dock). `home/dot_config/finicky/extras.json.tmpl` reads the port from the app's manifest at apply time, so re-adding the web app on a new port takes a re-apply; no app, no route.
- **Upgrades** go through topgrade's `Plannotator` step (`plannotator-upgrade`): binary update, Inbox restart when it lags the CLI, then the Claude plugin, which is versioned separately, in every config dir that has it.

## Key Conventions

- Prefer standalone scripts in `home/dot_local/bin/` over shell functions (unless the command must modify shell state)
- Env vars and PATH shared by zsh and bash live in `home/dot_config/shell/{env,path}.sh` (POSIX sh). zsh sources them from `.zshenv`/`.zprofile`; `dot_bashrc` sources them for bash, which Claude Code uses as its shell via `CLAUDE_CODE_SHELL`. Don't add exports to the zsh files directly
- Use `run_onchange_` scripts for auto-reload on config changes
- Store reusable data in `home/.chezmoidata/` or `data/`
- Use chezmoi template syntax (`{{ .variable }}`) for platform-specific configs
