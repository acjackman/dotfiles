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
| `config.toml` | Additive config — only the `vim-herdr-navigation` keybindings. herdr ships built-in defaults and writes no default config.toml, so keep this minimal. |
| `executable_ghostty-herdr` | Opens a new Ghostty window running herdr (the herdr analogue of `ghostty-sesh`). Run it, or bind it, to launch the trial. |
| `executable_ghostty-herdr-cmd` | Helper run inside the new Ghostty window; execs `herdr`. |
| `run_onchange_after_setup-herdr.sh.tmpl` | Installs the herdr plugins (below) if missing and reloads a running server after `config.toml` changes. Guarded on herdr being installed. |
| `plugins/config/kichel.muster/config.toml` | muster's own config (the projects it offers). herdr's plugin config dir lives under `~/.config/herdr/`, so chezmoi manages it here instead of hand-copying upstream's `config.toml.example`. |

## Plugins

- **vim-herdr-navigation** (`paulbkim-dev/vim-herdr-navigation`) — see below.
- **acjackman.title-rename** (`acjackman/herdr-title-rename`) — our own plugin;
  see below. Replaced `rjyo.window-title-sync`, which the `run_onchange` script
  uninstalls on sight (only one plugin can own the window title).
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

## acjackman.title-rename (window title + auto-naming)

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
(`tilde|full|basename|none`), `rename_tabs`, `rename_workspaces`. Not managed by
chezmoi yet — add it under `plugins/config/` like muster's if it ever needs
pinning.

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

The inverse — move the focused pane *into* another workspace/tab, herdr's
`join-pane`/`move-pane` — is `prefix+m` (from [herdr discussion
#1793](https://github.com/herdrdev/herdr/discussions/1793)). It's a
`type = "pane"` command, not `shell`: it drives two fzf pickers (workspace, then
tab within it, with a `new` entry to create one) off a single `herdr api
snapshot`, so it needs a TTY and herdr runs it in a pane. Needs `fzf` + `jq`.
The `pane zoom --off` calls on both ends stop the moved pane landing hidden
behind a zoom.

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

## `clank` substrate adapter (`~/.local/bin/clank`)

`spawn` and XO's clanker tracking both need the same primitive — "open
a new interactive surface running a command, then ask what state it's in." The
`clank` script is that adapter: it detects herdr and uses it when it's the active
multiplexer, falling back to tmux otherwise, so herdr stays **additive**
(tmux-only machines are unchanged).

**Verbs:** `clank open` (core primitive), `clank spawn` (a Claude work-agent),
`clank list` (JSONL of tracked agents), `clank state <label>` (semantic state),
`clank watch` (poll-based state-change stream), `clank close <label>` (tear down
the surface tagged `label` — herdr workspace close or tmux window kill), `clank
backend` (which backend the current context resolves to).

**Backend dispatch (coexistence rule):** a surface opened inside a herdr context
(`$HERDR_ENV`/`$HERDR_SESSION`) opens in herdr; one opened inside `$TMUX` opens in
tmux — never crossed, so a session stays inside one multiplexer. With no host
context, herdr wins when its server is up, else tmux. Override with `--backend` /
`$CLANK_BACKEND`.

**Identity:** herdr IDs are ephemeral (compacted on close), so the durable key is
the **workspace `--label`** (an effort/ticket id), re-queried every call — never
cached. On tmux the key is the `@clank_label` pane option (set with `-p`, so it
doesn't leak across the session). herdr's own `agent` targets are keyed by agent
*name* (`claude`) not our label, so operate on the `pane_id`/`workspace_id` that
`clank` reports (e.g. `herdr pane read <pane_id>`, `herdr workspace focus <ws>`).

**XO vs general:** every `clank` surface is tracked (`@clank_label` / workspace
label), but only surfaces opened with `--xo` are marked as part of XO's *managed
fleet of clankers* (tmux `@xo_agent`; surfaced as `xo:true` in `clank
list`/`state`). XO's launcher passes `--xo`; a general `clank open` / `/spawn`
does not, so plain spawns never count as XO agents. (herdr has no tag
equivalent — XO tracks its herdr agents by the labels it recorded.)

**Version gate:** herdr's wire protocol churns pre-1.0 and needs a server restart
on upgrade, so `clank` only uses herdr when `herdr status server` reports a
protocol in `$CLANK_HERDR_PROTOCOLS` (default `14 15 16 17`); an unrecognised protocol
degrades to tmux with a warning. Bump that env (or the default) after vetting a
new herdr release. herdr is pinned via `brew "herdr"` in `Brewfile-personal.tmpl`.

**Callers:** `~/.claude/commands/spawn.md` launches via `clank spawn`, verifies
via `clank state`, and tears down via `clank close`; `spawn-tmux` is now a thin
shim over `clank spawn --backend tmux`.

## Upgrades break the running server (`,doctor-herdr`)

The wire protocol churns pre-1.0 and `brew upgrade herdr` replaces the binary
**in place**, leaving the running server on the old protocol. Every CLI call
from the new binary is then rejected with `protocol_mismatch` — and since every
plugin drives the `herdr` CLI, **all the plugins stop working at once** while
herdr itself keeps running fine. `clank` degrades to tmux for the same reason.

A **second, quieter** failure shares the same cause. Even when the protocol still
matches, the surviving server can keep serving its **old keybinding table** and
silently drop the `[[keys.command]]` custom commands — the keys just do nothing,
with no log line, while every built-in and `plugin_action` binding keeps working.
(Seen 2026-07-30: the 0.7.5 upgrade killed the `prefix+t` / `prefix+shift+t`
break-pane bindings while `herdr config check`, `herdr status server`, and
`herdr pane move` on the CLI were all healthy.) The fix is
`herdr server reload-config`. Nothing triggers it on its own —
`run_onchange_after_setup-herdr.sh.tmpl` only reloads when `config.toml`
*changes*, and an upgrade changes the binary, not the config — so `,doctor-herdr`
now runs it unconditionally.

`,doctor-herdr` diagnoses the protocol mismatch (`herdr status server` reports
`compatible: no`).
It does **not** self-heal: the fix is a server restart, which kills every pane
process including running agents, so it reports by default and restarts only
under `,doctor-herdr --restart`. Session layout is persisted and restores; pane
processes do not. Relaunch afterwards with `~/.config/herdr/ghostty-herdr`.

After vetting the new release, add its protocol to `CLANK_HERDR_PROTOCOLS` in
`dot_local/bin/executable_clank` — otherwise `clank` keeps falling back to tmux
even once the server is restarted.

## Apply notes

`chezmoi apply` deploys these files and the `run_onchange` script reloads a
running herdr server via `herdr server reload-config`. To pick up keybinding
changes in an already-open herdr, reload from inside it (`prefix shift+c`) or run
`herdr server reload-config`.
