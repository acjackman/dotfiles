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

## `clank` substrate adapter (`~/.local/bin/clank`)

`spawn`, `revdiff`, and XO's clanker tracking all need the same primitive — "open
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
protocol in `$CLANK_HERDR_PROTOCOLS` (default `14`); an unrecognised protocol
degrades to tmux with a warning. Bump that env (or the default) after vetting a
new herdr release. herdr is pinned via `brew "herdr"` in `Brewfile-personal.tmpl`.

**Callers:** `~/.claude/commands/spawn.md` launches via `clank spawn`, verifies
via `clank state`, and tears down via `clank close`; `spawn-tmux` is now a thin
shim over `clank spawn --backend tmux`; `~/.claude/skills/revdiff/launch-revdiff.sh`
adds a herdr-pane path beside its tmux-window path.

## Other herdr integrations

`dot_config/worktrunk/hooks/wt-mux-hook.sh` (worktrunk's `[pre-remove]` /
`[pre-merge]` hook) scans herdr panes as well as tmux ones, so a busy herdr pane
blocks a `wt remove` that would delete the worktree under it. It talks to herdr
directly rather than through `clank` — `clank list` only enumerates *tagged*
surfaces, whereas the hook has to see every pane, whichever multiplexer it sits
in. Deliberately **not** subject to the coexistence rule above: that rule is about
choosing one substrate to *open* on, while a safety check wants to see everything.
It shares `$CLANK_HERDR_PROTOCOLS` for the version gate.

## `herdr pane current` vs `$HERDR_PANE_ID`

herdr exports `HERDR_PANE_ID` / `HERDR_TAB_ID` / `HERDR_WORKSPACE_ID` / `HERDR_ENV`
into every pane's environment — `HERDR_PANE_ID` is the direct analogue of
`$TMUX_PANE` and is the right way to ask "which pane am I?".

`herdr pane current` resolves by **controlling TTY**, and when the caller isn't a
herdr pane it does not fail — it falls back to returning the **focused** pane
(verified against herdr 0.7.1). So it can't answer "am I herdr-hosted?" on its
own: from tmux, or from any process without a herdr ctty, it returns a pane
regardless. Prefer `$HERDR_PANE_ID` for identity, and treat a non-empty `herdr
pane current` as "a herdr server is up and something is focused", not as "I am
that pane". (`clank`'s `herdr_hosted` relies on `herdr pane current` failing when
unhosted, and the docs above describe it as dispatching on `$HERDR_ENV` —
worth reconciling.)

## Apply notes

`chezmoi apply` deploys these files and the `run_onchange` script reloads a
running herdr server via `herdr server reload-config`. To pick up keybinding
changes in an already-open herdr, reload from inside it (`prefix shift+r`) or run
`herdr server reload-config`.
