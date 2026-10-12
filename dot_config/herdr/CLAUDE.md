# Herdr Config

[herdr](https://herdr.dev) is an agent-aware terminal multiplexer being trialled
as a side-by-side alternative to tmux (it does **not** replace the tmux setup in
`dot_config/tmux/`). Installed via `brew "herdr"` in `Brewfile-personal.tmpl`.

**Agent reference:** for concepts, commands, and troubleshooting beyond this
repo's setup, see the upstream agent guide at <https://herdr.dev/agent-guide.md>
(canonical docs: <https://herdr.dev/docs/>).

## Files

| File | Purpose |
|------|---------|
| `modify_config.toml` | Additive config (keybindings, a few in-app settings). A chezmoi **modify template**, not a plain file — herdr-radar co-owns `config.toml`; see [herdr-radar](#herdr-radar-co-owns-configtoml). |
| `run_onchange_after_setup-herdr.sh.tmpl` | Installs the herdr plugins (below) if missing, re-enables `acjackman.title-rename` if an earlier run disabled it, and reloads a running server after `modify_config.toml` changes. Guarded on herdr being installed. |
| `run_after_ensure-herdr-integrations.sh` | Every apply: installs/upgrades herdr's agent integrations for claude, codex, pi, omp (and each `~/.config/claude/profiles/*`). Silent when all are current. See [Agent integrations](#agent-integrations). |
| `plugins/config/acjackman.title-rename/config.toml` | Turns off title-rename's tab/workspace renaming (`rename_tabs`/`rename_workspaces = false`), leaving only the window title. |
| `plugins/config/kichel.muster/config.toml` | muster's own config (the projects it offers). herdr's plugin config dir lives under `~/.config/herdr/`, so chezmoi manages it here instead of hand-copying upstream's `config.toml.example`. |

## Plugins

- **vim-herdr-navigation** (`paulbkim-dev/vim-herdr-navigation`) — see below.
- **acjackman.title-rename** (`acjackman/herdr-title-rename`) — our own plugin;
  **title only** (2026-10-11): sets the outer window title for Timing; its
  tab/workspace renaming is off in its config because the naming logic didn't
  fit herdr. herdr-bar's auto titles name tabs instead. See below.
- **hhdebb.herdr-radar** (`hhdebb/herdr-radar`) — readable Agents sidebar:
  vendor logos, grouping by activity, stale rows dimmed, worktrees nested under
  their repo. `prefix+a` flips active/recent order, `prefix+comma` opens its
  settings. Node 18+. Installs an icon font (Herdr Agent Icons Max) and **writes
  into other config files** — see below.
- **herdr-bar** (`jeffarese/herdr-bar`) — Cmd+K-style fuzzy switcher over agents,
  tabs, named panes and workspaces, with live preview, on `prefix+k`. Its
  background watcher also auto-titles unnamed Claude/Codex tabs from the task
  title (`auto_titles`, default on; config in `herdr plugin config-dir
  herdr-bar`/`config.json`, not managed). Python 3 stdlib only. Shares radar's
  icon font for agent logos.
- **heeler** (`ZingerLittleBee/Heeler/plugin`, `--ref main`) — **Odin only**
  (`eq .hostname "Odin"` in the `run_onchange` script). Server half of the
  [Heeler](https://github.com/ZingerLittleBee/Heeler) iOS app: remote access to
  this machine's agents over plain SSH, plus encrypted push notifications when
  an agent blocks/finishes. Needs Node 20+ (`npm ci` build) and macOS **Remote
  Login** on. Pair a phone with `herdr plugin action invoke heeler.pair` (QR in a
  herdr popup); pairing appends the device key to `~/.ssh/authorized_keys`. A
  non-22 SSH port goes in `pair.json` in its config dir.
- **worktrunk** (`devashish2203/herdr-worktrunk`) — worktree switch/create
  (`prefix+shift+g`) and remove (`prefix+shift+d`) via worktrunk (`wt`) + fzf,
  the herdr analogue of the tmux `wt-sesh-select` bindings. Needs `wt` ≥ 0.60,
  `fzf`, `jq`. `open_mode` (nested `workspace` vs new `tab`) is set in the
  plugin's own config dir (`herdr plugin config-dir worktrunk`); default is
  `workspace`.
- **kichel.muster** (`marcoskichel/herdr-muster`) — agent-aware project switcher
  bound to `prefix+enter`; see below.
- **rmarganti.herdr-pluck** (`rmarganti/herdr-pluck`) — tmux-fingers-style hint
  picker bound to `prefix+space`: overlays keyboard hints on the visible copyable
  tokens and copies the chosen one (via `pbcopy`). Needs herdr ≥ 0.7.0; ships
  prebuilt binaries for macOS Apple Silicon / Linux x86_64, else builds via Cargo
  (Rust already present for muster). No `config.toml` of its own required —
  patterns can be tuned via its plugin config dir or a project-local
  `.herdr-pluck.toml` if ever needed.
- **jt.command-palette** (`JanTvrdik/herdr-command-palette`) — fzf command
  palette bound to `prefix+p`: fuzzy-pick and run any action exposed by any
  installed plugin (`herdr plugin action list`), so plugin actions that don't
  warrant their own key are still reachable. Pure bash; needs `fzf` + `jq` (both
  already required by worktrunk). herdr actions run server-side without a TTY, so
  the plugin opens an **overlay pane** to host fzf and forwards the origin
  workspace's cwd, keeping context-aware actions pointed at the right repo.
  herdr 0.7 ignores keys declared in a plugin manifest — hence the explicit
  `[[keys.command]]` entry in `config.toml`.
- **drovr** (`applifaction/herdr-drovr`, a fork of `AVGVSTVS96/herdr-drovr`) —
  move the focused pane into any tab
  (`prefix+m`) or the whole tab to another workspace (`prefix+shift+m`) from an
  fzf popup. Relocates live panes via `herdr pane move` rather than respawning,
  so running agents survive; a tab move replays the split layout from the rects
  herdr reports. A tab move is several `pane move` calls with **no rollback** —
  a mid-way failure leaves the tab split across both places. Runs its `.ts`
  sources directly with node type stripping (upstream asks for node ≥ 23; node
  22.18+ also strips by default), so `node` must resolve on the **herdr
  server's** PATH — if the keys silently do nothing, check
  `herdr plugin log list --plugin drovr`. Also needs `fzf`. **Why the fork:**
  upstream focused the destination with separate commands *after* the move,
  but herdr closes the picker popup once the source tab empties (always, for a
  tab move), killing the picker first, so focus stayed behind. The fork puts
  `--focus` on the final `pane move`. Caveat: after a multi-pane tab move,
  focus lands on the last pane placed, not the one that was focused. Upstream
  has never merged an outside PR, so the setup script uninstalls any `drovr`
  installed from a different repo and reinstalls from the fork.

## herdr-radar co-owns config.toml

radar writes three **marker-fenced blocks** (`# >>> herdr-radar <name> block` …
`# <<< …`) into herdr's `config.toml`: `tab-bar` (inside `[ui]`), `theme`
(`[theme.custom]`) and `sidebar` (`[ui.sidebar.*]`). They are big, carry
absolute paths, and the theme block is **rewritten on every light/dark flip**.
A plain chezmoi file would strip them on each apply and radar would put them
back — permanent drift. So the source is `modify_config.toml`, a chezmoi
`modify-template`: everything is ours except those three blocks, which it lifts
verbatim from the live file (`.chezmoi.stdin`) and puts back in place. On a fresh
machine they're absent until radar's daemon first starts. Don't add your own
`[theme.custom]` or `[ui.sidebar.*]` table — TOML allows each once and radar
will skip its block.

radar also writes a `font` block (codepoint map for its icon font) into
**ghostty** and **kitty** configs. Those are static, so they're simply mirrored
verbatim at the end of `dot_config/ghostty/config.tmpl` and
`dot_config/kitty/kitty.conf`. If a radar upgrade widens the ranges,
`chezmoi diff` shows it — adopt the new lines.

## acjackman.title-rename (window title + auto-naming) — title only

**Renaming off since 2026-10-11** — the naming logic wasn't right for herdr, so
`plugins/config/acjackman.title-rename/config.toml` sets `rename_tabs` and
`rename_workspaces` to `false`. The title half still runs, so Timing keeps its
attribution. Tab naming comes from herdr-bar's auto titles. To bring renaming
back, fix the plugin and flip those flags. The rename notes below describe the
disabled half.

[acjackman/herdr-title-rename](https://github.com/acjackman/herdr-title-rename)
is ours, written for this setup. It reproduces the tmux titling in
`dot_config/tmux/tmux.conf` on herdr:

```
workspace | tab | ~/path      # tmux: set-titles-string '#S | #W | ~/path'
```

**Why it exists.** The [Timing](https://timingapp.com) time tracker attributes
terminal work by parsing the window title, and its rules were built against the
tmux format. herdr has no built-in window-title setting at all — the only lever
is the `client.window_title.set` API — and no published plugin puts the focused
pane's directory in the title, so moving work into herdr made that time
invisible. Hence: keep the title byte-compatible with tmux and Timing keeps
working.

**Two halves.** The title half sets the outer Ghostty title from the focused
workspace label, tab label, and pane cwd. The rename half auto-names tabs and
workspaces from the active pane's git worktree — ports of `tmux-window-name`
(worktree basename) and `tmux-session-name` (`repo`, or `repo/branch` off the
default branch; `wt config state default-branch` supplies the default). The
sesh lookup in `tmux-session-name` is dropped — herdr has no sesh.

**Manual renames win permanently**, the way tmux stops managing a window you
`rename-window`. The plugin records every label it writes; a label that reads
back different was changed by hand, and that tab or workspace is released.
Labels it has never owned are adopted only while still at herdr's default (the
tab/workspace number) — so the workspaces that existed before install keep
their names for good, and only new ones get auto-named.

**Known limitation: a bare `cd` does not refresh the title.** herdr's *plugin
manifest* honours a narrower event set than its socket API. `pane.updated` — the
event carrying a pane's cwd and terminal-title changes — is valid for
`events.subscribe` over the socket but rejected in a manifest (`unknown event`
at install, then silently never delivered). Verified on 0.7.5 by linking a probe
manifest; `layout.updated`, `pane.cwd_changed`, `pane.output_changed`,
`pane.renamed`, `pane.scroll_changed`, `pane.title_changed`, and
`workspace.metadata_updated` are rejected too. So the title tracks focus and
structure changes, not `cd` inside the pane you are already in — switch panes to
catch up, or `herdr plugin action invoke acjackman.title-rename.refresh`. The
fix is a startup watcher holding a socket subscription; not built yet.

**Config** (all optional, defaults reproduce the tmux format) lives in
`herdr plugin config-dir acjackman.title-rename`: `separator`, `path_style`
(`tilde|full|basename|none`), `rename_tabs`, `rename_workspaces`. Managed by
chezmoi at `plugins/config/acjackman.title-rename/config.toml`.

**Install builds from source** (`cargo build --release`), so it shares muster's
dependency on `brew "rust"`. Unlike the bun-based plugin it replaced, it needs
no runtime.

**Local development:** the source lives at `~/dev/jackman/herdr-title-rename`
(worktrunk bare layout). To test a working copy against the running server,
`herdr plugin link "$PWD"` from the worktree — but uninstall the GitHub-installed
copy first, or two builds race for the title. `--dry-run` prints the renames and
title it *would* apply and touches nothing, which is the safe way to check naming
rules against a live session.

## Keybindings

`config.toml` overrides `[keys]` actions toward the tmux muscle memory in
`dot_config/tmux/tmux.reset.conf`: `prefix = ctrl+space`, `detach = prefix+d`,
`|`/`-` splits, plus tmux-faithful tab ops — `new_tab = prefix+n`,
`close_tab = prefix+w`, `rename_tab = prefix+r`, and `workspace_picker = prefix+o`
(the sesh-picker analogue, since herdr workspaces ≈ tmux sessions). Workspaces
being the session analogue, `rename_workspace = prefix+shift+r` sits on the
shifted rename key next to `rename_tab`. Each reclaimed key relocates the herdr
default it displaced (`next_tab → prefix+shift+p`, `resize_mode → prefix+ctrl+r`,
`reload_config → prefix+shift+c`) so one action owns each key. herdr validates
keybindings and logs `invalid keybinding` warnings to `herdr-server.log`; press
`prefix+?` in-app for the live list.

Two `[[keys.command]]` shell bindings break the focused pane out (herdr has no
built-in action for it, so they drive the `herdr pane move` CLI on
`$HERDR_ACTIVE_PANE_ID` — the keybinding-context var, not the pane-shell's
`HERDR_PANE_ID`; the herdr analogue of tmux `break-pane`): `prefix+t` →
`--new-tab`, `prefix+shift+t` → `--new-workspace`.

The inverse — move the focused pane *into* another tab, herdr's
`join-pane`/`move-pane` — is `prefix+m`, and `prefix+shift+m` moves the whole
tab to another workspace. Both are **drovr** plugin actions (see Plugins):
lowercase acts on the pane, shift on the tab, mirroring `t`/`shift+t`.

`prefix+m` used to be an inline `type = "pane"` fzf script from [herdr
discussion #1793](https://github.com/herdrdev/herdr/discussions/1793) (two
pickers, workspace then tab; in git history). drovr replaced it for the single
popup picker, cross-workspace toggle, down-splits, naming, and focus-follow. The
one thing lost: the script ran `pane zoom --off` on both ends, so a pane moved
into a **zoomed** tab can now land hidden behind the zoom — unzoom that tab if
a move seems to vanish.

`prefix+k` opens herdr-bar (reclaims herdr's `focus_pane_up` — not relocated,
since `ctrl+k` already moves up via vim-herdr-navigation). `prefix+a` /
`prefix+comma` are herdr-radar's order flip and settings popup.

`prefix+.` opens [navi](https://github.com/denisidoro/navi) as a 90%x90% popup
and types the chosen snippet into the pane you came from, without Enter. It
ports tmux's `l-lin/tmux-navi` popup (`dot_config/tmux/tmux.conf`) onto tmux's
own navi key, `prefix .` (`dot_config/tmux/tmux.reset.conf`) — the popup
presentation of the one, the muscle memory of the other. Both surfaces keep
their own binding; nothing was removed from tmux.

herdr has no navi plugin, so the popup body is a script:
`dot_local/bin/,herdr-navi`. Three things it exists to handle:

- **`type = "popup"`, not `shell`.** navi drives fzf and needs a TTY; a `shell`
  command runs headless. A popup is session-modal and leaves the tab layout
  alone — herdr's `display-popup`. (`width`/`height` are only legal on `popup`.)
- **Target pane.** Popups get `HERDR_ACTIVE_PANE_ID` and explicitly *not*
  `HERDR_PANE_ID` — it points at the underlying tiled pane. Same trap as the
  break-pane bindings above. The script's `pane list`/`focused` fallback only
  matters when you run it by hand.
- **Bracketed paste.** `herdr pane send-text` is low-level and non-submitting:
  unlike `pane run` and `agent prompt` it does **not** honour the pane's
  bracketed-paste mode, and `pane.send_text` takes only `{pane_id, text}` (no
  paste flag — see `herdr api schema --json`). A multi-line snippet would arrive
  as literal Enters and execute its intermediate lines, so the script wraps the
  payload in `ESC[200~`/`ESC[201~` itself, reproducing tmux's `paste-buffer -p`.
  If that ever stops passing through, `HERDR_NAVI_NO_BRACKET=1` sends raw and
  limits you to single-line snippets.

The shell-level navi widget (`navi widget zsh`, `Ctrl+G`, in
`dot_config/zsh/zshrc.zsh.tmpl`) is independent of all this and already works
inside herdr panes. Cheatsheets live in `dot_local/share/navi/cheats/`.

## vim-herdr-navigation

`<C-h/j/k/l>` moves between herdr panes and Neovim splits (port of
vim-tmux-navigator). Two sides:

- **herdr side** — `config.toml` binds the keys to the plugin's actions; the
  plugin is installed from `paulbkim-dev/vim-herdr-navigation` by the
  `run_onchange` script (`herdr plugin install …`).
- **Neovim side** — `dot_config/nvim/lua/exact_plugins/windows.lua` embeds the
  plugin's nav logic. It falls back to `:TmuxNavigate*` when `$TMUX` is set, so
  the same mappings work in both herdr and tmux.

## muster (project switcher)

[muster](https://github.com/marcoskichel/herdr-muster) (`kichel.muster`) is a
fuzzy project switcher inspired by [sesh](https://github.com/joshmedeski/sesh):
one keypress gives a list of projects, the already-running ones first and tagged
with their agent's state (blocked / working / done / idle), blocked at the top.
Each project maps to exactly one workspace, and muster remembers that pairing, so
it never opens a second workspace for the same repo. Bound to `prefix+enter`
(upstream suggests `prefix+space`, but that now drives herdr-pluck; `prefix+o` is
deliberately left alone — see the commented-out `workspace_picker` in
`config.toml`).

**Install needs Rust.** `herdr plugin install` compiles muster from source, so it
depends on `brew "rust"` in `Brewfile-base` (already there for nvim's mason).

**The bare-repo gotcha.** muster's `roots` scan only counts a directory as a
project when its `.git` is a **directory**; it deliberately skips linked worktrees
and submodules (`.git` is a *file*). The worktrunk bare repos here (`,gr-bare`:
a `.bare/` dir plus a `.git` file, every checkout a linked worktree) therefore
never show up from a `roots` scan — including `infra` and `bumper`. The same
filter is applied to zoxide results, so zoxide can't rescue them either. Only
`paths` bypasses the filter, so those repos are listed explicitly in
`plugins/config/kichel.muster/config.toml`.

**So: a new `,gr-bare` / `,gr-clone` repo must be added to that `paths` list** or
it won't appear in the switcher. A plain `git clone` under an existing root needs
no change.

muster and worktrunk (`prefix+shift+g`) are complementary, and the split follows
that same distinction: muster picks a *project*, worktrunk switches *worktrees*
within one.

## Surfaces: drive herdr (or tmux) directly

`/spawn` and XO's fleet tracking both need the same primitive — "open a new
interactive surface running a command, then ask what state it's in." **Agents
call `herdr` (or `tmux`) directly for this.** There is no adapter in between.

`clank` used to be that adapter. It was **removed** on 2026-08-04 — see the
section below.

### Pick the substrate

Detect, don't assume. In order:

1. `herdr pane current` exits 0 → you are inside a herdr pane → **herdr**.
   (Probe with the command, not `$HERDR_ENV`/`$HERDR_SESSION` — those are plain
   env vars a child process can inherit from a *different* live pane.)
2. `$TMUX` is set → you are inside tmux → **tmux**.
3. Neither → `herdr status server` succeeds → **herdr**; else **tmux**.

Never cross: a surface opened from inside tmux stays in tmux, and vice versa.

### herdr: open, inspect, close

```bash
# open — an isolated workspace per agent, in the background
ws_json=$(herdr workspace create --cwd "$WORKTREE" --label "$LABEL" --no-focus)
ws=$(jq -r '.result.workspace.workspace_id' <<<"$ws_json")    # e.g. w6S
pane=$(jq -r '.result.root_pane.pane_id'    <<<"$ws_json")    # e.g. w6S:p1

# launch — `pane run` types the line into that workspace's shell and hits Enter,
# so the shell evaluates the pipe. Unset $TMUX first: the herdr server can carry
# a stale one that every pane inherits, which breaks `tmux display-popup`
# (revdiff) inside a surface that is not actually a tmux client.
herdr pane run "$pane" "unset TMUX TMUX_PANE; cat $PROMPT_FILE | claude \
  --permission-mode=auto --name $LABEL \
  --settings '{\"enableAllProjectMcpServers\":true}' --model $MODEL"

herdr agent list                      # whole fleet + semantic state
herdr agent get "$pane"               # one agent
herdr pane read "$pane" --lines 30    # raw buffer, for diagnosing a failed launch
herdr workspace focus "$ws"
herdr workspace close "$ws"
```

`--settings '{"enableAllProjectMcpServers":true}'` keeps an autonomous agent from
stalling on the "N new MCP servers found — enable?" prompt for an unapproved
project `.mcp.json`. It auto-approves *project*-scoped servers only, leaving
global/user MCP untouched (unlike `--strict-mcp-config`, which would drop them).

**Identity — the rule that matters.** Operate on the **`workspace_id`**, resolved
fresh from `herdr workspace list` at the moment you act. Labels are **not
unique**, so closing by label can tear down the wrong surface. The label is for
*human/ticket association*; the workspace ID is the *operational handle*. IDs are
compacted on close, so re-resolve every call rather than caching one across turns.

`herdr agent` targets are keyed by agent *name* or *pane id* — not by workspace
label — so join through `workspace_id`:

```bash
# label -> workspace_id -> agent state
herdr workspace list | jq -r --arg l "$LABEL" \
  '.result.workspaces[] | select(.label==$l) | .workspace_id'
herdr agent list | jq -c --arg ws "$ws" \
  '.result.agents[] | select(.workspace_id==$ws) | {agent, agent_status, pane_id}'
```

Agent states are semantic and authoritative: `working` / `idle` / `blocked`
(an approval or question UI) / `done` (idle after unseen background work) /
`unknown` (an agent is present but unclassifiable — **not** proof of completion).

### tmux: same three operations

tmux has no semantic agent state; classifying a Claude pane means scraping its
buffer. Treat that as a heuristic, and say so when you report it.

```bash
pane=$(tmux new-window -n "$LABEL" -c "$WORKTREE" -d -P -F '#{pane_id}')
tmux set-option -t "$pane" automatic-rename off
tmux set-option -p -t "$pane" @agent_label "$LABEL"   # -p, or it leaks session-wide
tmux send-keys -t "$pane" "cat $PROMPT_FILE | claude --permission-mode=auto ..." Enter

tmux list-panes -a -f '#{@agent_label}' -F '#{@agent_label}	#{pane_id}	#{pane_current_path}'
tmux capture-pane -p -t "$pane" | tail -30
tmux kill-window -t "$pane"
```

Use `tmux new-session -d -s "$LABEL" -c "$WORKTREE"` instead when a *session*
(not a window) is wanted. On herdr that distinction collapses — every surface is
its own workspace.

### Removed: the `clank` adapter (2026-08-04)

**`clank` is gone** — deleted, not shimmed. A `clank: command not found` is the
intended outcome: it surfaces a stale call site immediately, where a warning
would have let one linger. If you hit one, port it to the recipes above.

It wrapped herdr and tmux behind `open|spawn|list|state|watch|close`, dispatching
on context. The portability argument for that wrapper evaporated once herdr was
fully adopted, and what remained was strictly lossier than what it wrapped: it
discarded unique workspace IDs in favour of collision-prone labels, exposed only
polling where herdr has `events.subscribe`, and flattened "closed" to `unknown`.
Its `CLANK_HERDR_PROTOCOLS` allow-list had also gone stale (capped at 17 against
herdr's live protocol 19), so it had been silently degrading every spawn to tmux.

`spawn-tmux` used to be a shim over `clank spawn --backend tmux`; it is now
self-contained (direct `tmux` calls) and stays as the hand-typed tmux CLI.

Two things went away with it rather than being ported:

- **`--xo` fleet tagging.** It only ever worked on tmux (`@xo_agent`); herdr had
  no equivalent. It was also redundant — the XO contract is to enumerate the
  *whole* fleet and adopt surfaces it didn't launch. XO's fleet is now "every
  live surface except XO's own workspace."
- **The `CLANK_HERDR_PROTOCOLS` version gate.** A protocol mismatch now surfaces
  as a plain herdr CLI error instead of a silent downgrade to tmux. That is the
  better failure: `,doctor-herdr` diagnoses it, and a silent substrate switch was
  never something a caller could reason about.

## Upgrades break the running server (`,doctor-herdr`)

The wire protocol churns pre-1.0 and `brew upgrade herdr` replaces the binary
**in place**, leaving the running server on the old protocol. Every CLI call
from the new binary is then rejected with `protocol_mismatch` — and since every
plugin drives the `herdr` CLI, **all the plugins stop working at once** while
herdr itself keeps running fine. Agent surface control fails the same way, for
the same reason.

A **second, quieter** failure shares the same cause. Even when the protocol still
matches, the surviving server can keep serving its **old keybinding table** and
silently drop the `[[keys.command]]` custom commands — the keys just do nothing,
with no log line, while every built-in and `plugin_action` binding keeps working.
(Seen 2026-07-30: the 0.7.5 upgrade killed the `prefix+t` / `prefix+shift+t`
break-pane bindings while `herdr config check`, `herdr status server`, and
`herdr pane move` on the CLI were all healthy.) The fix is
`herdr server reload-config`. Nothing triggers it on its own —
`run_onchange_after_setup-herdr.sh.tmpl` only reloads when `modify_config.toml`
*changes*, and an upgrade changes the binary, not the config — so `,doctor-herdr`
now runs it unconditionally.

`,doctor-herdr` diagnoses the protocol mismatch (`herdr status server` reports
`compatible: no`).
It does **not** self-heal: the fix is a server restart, which kills every pane
process including running agents, so it reports by default and restarts only
under `,doctor-herdr --restart`. Session layout is persisted and restores; pane
processes do not. Relaunch afterwards with `~/.config/ghostty/ghostty-herdr`.

Since agents drive the `herdr` CLI directly, a mismatch is loud: calls fail with
`protocol_mismatch` rather than silently degrading to another substrate. Restart
the server and retry; there is no protocol allow-list to bump any more.

## Agent integrations

`herdr integration install <agent>` drops a hook/extension into each agent so it
reports its session ID to herdr (resume agent panes after a server restart —
what makes `,doctor-herdr --force-restart` survivable) and, for pi/omp, its
state directly instead of herdr scraping the screen. herdr-bar's Claude
transcript titles and herdr-radar's activity timing read the same session data.

`run_after_ensure-herdr-integrations.sh` keeps them current on every apply
(`run_after_`, because a herdr upgrade bumps integration versions without any
source change here). It checks `herdr integration status` — local files only,
no server — and reinstalls anything not `current`. Where each one writes:

- **pi / omp** — an extension file under `~/.pi/agent/extensions/`,
  `~/.omp/agent/extensions/`. omp's installer refuses until omp has created that
  dir on first run, so the script skips omp until then.
- **claude** — `hooks/herdr-agent-state.sh` + a `SessionStart` entry in
  `settings.json`. `dot_claude/run_onchange_after_generate_settings.sh.tmpl`
  preserves hooks it doesn't own (verified). Repeated per Claude profile via
  `CLAUDE_CONFIG_DIR`, which herdr honours for both status and install.
- **codex** — `herdr-agent-state.sh` + `hooks.json` in `$CODEX_HOME`
  (`~/.config/codex`), plus `[features] hooks = true` in `config.toml`. That file
  is **generated** from `config.d/`, and `integration status` only checks the
  hook script — so the flag lives in
  `dot_config/codex/exact_config.d/10-features.toml`, or a config rebuild would
  silently disable the integration while status still says `current`.

## Plugins need the server's PATH

Plugin commands (startup hooks, actions, event hooks) run with the **herdr
server's** environment, not the caller's. A server started from a GUI context
(Tuna, launchd) gets launchd's bare PATH — `/usr/bin:/bin:/usr/sbin:/sbin` — so
every node plugin (radar, heeler, drovr) fails with `No such file or directory
(os error 2)` in `herdr plugin log list`, while herdr-bar keeps working on
macOS's `/usr/bin/python3`. Check with
`ps eww -o command= -p "$(pgrep -f 'herdr server')" | tr ' ' '\n' | grep ^PATH=`.

**A live handoff does not fix it** — the replacement server inherits the old
server's environment (verified 2026-10-11). Only a real restart from a good
shell does: `,doctor-herdr --force-restart` (kills pane processes; plain
`--restart` only acts on a protocol mismatch, which this is not).
`dot_config/ghostty/executable_ghostty-herdr-cmd` prevents it by loading the
login-shell PATH plus mise shims before exec'ing herdr.

There is no "reload plugins" command. `herdr server reload-config` picks up
keybindings; plugin startup hooks rerun only on server start or live handoff
(`herdr server live-handoff --import-exe "$(command -v herdr)"`), not on
enable/disable.

## Apply notes

`chezmoi apply` deploys these files and the `run_onchange` script reloads a
running herdr server via `herdr server reload-config`. To pick up keybinding
changes in an already-open herdr, reload from inside it (`prefix shift+c`) or run
`herdr server reload-config`.
