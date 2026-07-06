# Herdr Config

[herdr](https://herdr.dev) is an agent-aware terminal multiplexer being trialled
as a side-by-side alternative to tmux (it does **not** replace the tmux setup in
`dot_config/tmux/`). Installed via `brew "herdr"` in `Brewfile-personal.tmpl`.

## Files

| File | Purpose |
|------|---------|
| `config.toml` | Additive config — only the `vim-herdr-navigation` keybindings. herdr ships built-in defaults and writes no default config.toml, so keep this minimal. |
| `executable_ghostty-herdr` | Opens a new Ghostty window running herdr (the herdr analogue of `ghostty-sesh`). Run it, or bind it, to launch the trial. |
| `executable_ghostty-herdr-cmd` | Helper run inside the new Ghostty window; execs `herdr`. |
| `run_onchange_after_setup-herdr.sh.tmpl` | Installs the herdr plugins (below) if missing and reloads a running server after `config.toml` changes. Guarded on herdr being installed. |

## Plugins

- **vim-herdr-navigation** (`paulbkim-dev/vim-herdr-navigation`) — see below.
- **rjyo.window-title-sync** (`rjyo/herdr-window-title-sync`) — syncs the
  terminal/Ghostty window title with the focused workspace/tab/agent. Purely
  event-driven (no keybindings or `config.toml` entries). Requires **bun** on
  `PATH`, provided by the global `bun` tool in `data/mise/config.toml`.
- **worktrunk** (`devashish2203/herdr-worktrunk`) — worktree switch/create
  (`prefix+shift+g`) and remove (`prefix+shift+d`) via worktrunk (`wt`) + fzf,
  the herdr analogue of the tmux `wt-sesh-select` bindings. Needs `wt` ≥ 0.60,
  `fzf`, `jq`. `open_mode` (nested `workspace` vs new `tab`) is set in the
  plugin's own config dir (`herdr plugin config-dir worktrunk`); default is
  `workspace`.

## Keybindings

`config.toml` overrides `[keys]` actions toward the tmux muscle memory in
`dot_config/tmux/tmux.reset.conf`: `prefix = ctrl+space`, `detach = prefix+d`,
`|`/`-` splits, plus tmux-faithful tab ops — `new_tab = prefix+n`,
`close_tab = prefix+w`, `rename_tab = prefix+r`, and `workspace_picker = prefix+o`
(the sesh-picker analogue, since herdr workspaces ≈ tmux sessions). Each reclaimed
key relocates the herdr default it displaced (`next_tab → prefix+shift+p`,
`resize_mode → prefix+shift+r`) so one action owns each key. herdr validates
keybindings and logs `invalid keybinding` warnings to `herdr-server.log`; press
`prefix+?` in-app for the live list.

## vim-herdr-navigation

`<C-h/j/k/l>` moves between herdr panes and Neovim splits (port of
vim-tmux-navigator). Two sides:

- **herdr side** — `config.toml` binds the keys to the plugin's actions; the
  plugin is installed from `paulbkim-dev/vim-herdr-navigation` by the
  `run_onchange` script (`herdr plugin install …`).
- **Neovim side** — `dot_config/nvim/lua/exact_plugins/windows.lua` embeds the
  plugin's nav logic. It falls back to `:TmuxNavigate*` when `$TMUX` is set, so
  the same mappings work in both herdr and tmux.

## `fleet` substrate adapter (`~/.local/bin/fleet`)

`spawn`, `revdiff`, and XO's fleet tracking all need the same primitive — "open
a new interactive surface running a command, then ask what state it's in." The
`fleet` script is that adapter: it detects herdr and uses it when it's the active
multiplexer, falling back to tmux otherwise, so herdr stays **additive**
(tmux-only machines are unchanged).

**Verbs:** `fleet open` (core primitive), `fleet spawn` (a Claude work-agent),
`fleet list` (JSONL of tracked agents), `fleet state <label>` (semantic state),
`fleet watch` (poll-based state-change stream), `fleet backend` (which backend
the current context resolves to).

**Backend dispatch (coexistence rule):** a surface opened inside a herdr context
(`$HERDR_ENV`/`$HERDR_SESSION`) opens in herdr; one opened inside `$TMUX` opens in
tmux — never crossed, so a session stays inside one multiplexer. With no host
context, herdr wins when its server is up, else tmux. Override with `--backend` /
`$FLEET_BACKEND`.

**Identity:** herdr IDs are ephemeral (compacted on close), so the durable key is
the **workspace `--label`** (an effort/ticket id), re-queried every call — never
cached. On tmux the key is the `@fleet_label` pane option (set with `-p`, so it
doesn't leak across the session). herdr's own `agent` targets are keyed by agent
*name* (`claude`) not our label, so operate on the `pane_id`/`workspace_id` that
`fleet` reports (e.g. `herdr pane read <pane_id>`, `herdr workspace focus <ws>`).

**XO vs general:** every `fleet` surface is tracked (`@fleet_label` / workspace
label), but only surfaces opened with `--xo` are marked as XO's *managed fleet*
(tmux `@xo_agent`; surfaced as `xo:true` in `fleet list`/`state`). XO's launcher
passes `--xo`; a general `fleet open` / `/spawn` does not, so plain spawns never
count as XO agents. (herdr has no tag equivalent — XO tracks its herdr agents by
the labels it recorded.)

**Version gate:** herdr's wire protocol churns pre-1.0 and needs a server restart
on upgrade, so `fleet` only uses herdr when `herdr status server` reports a
protocol in `$FLEET_HERDR_PROTOCOLS` (default `14`); an unrecognised protocol
degrades to tmux with a warning. Bump that env (or the default) after vetting a
new herdr release. herdr is pinned via `brew "herdr"` in `Brewfile-personal.tmpl`.

**Callers:** `~/.claude/commands/spawn.md` launches via `fleet spawn` and verifies
via `fleet state`; `spawn-tmux` is now a thin shim over `fleet spawn --backend
tmux`; `~/.claude/skills/revdiff/launch-revdiff.sh` adds a herdr-pane path beside
its tmux-window path.

## Apply notes

`chezmoi apply` deploys these files and the `run_onchange` script reloads a
running herdr server via `herdr server reload-config`. To pick up keybinding
changes in an already-open herdr, reload from inside it (`prefix shift+r`) or run
`herdr server reload-config`.
