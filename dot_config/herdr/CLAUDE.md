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
| `plugins/config/kichel.muster/config.toml` | muster's own config (the projects it offers). herdr's plugin config dir lives under `~/.config/herdr/`, so chezmoi manages it here instead of hand-copying upstream's `config.toml.example`. |

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
- **kichel.muster** (`marcoskichel/herdr-muster`) — agent-aware project switcher
  bound to `prefix+enter`; see below.
- **rmarganti.herdr-pluck** (`rmarganti/herdr-pluck`) — tmux-fingers-style hint
  picker bound to `prefix+space`: overlays keyboard hints on the visible copyable
  tokens and copies the chosen one (via `pbcopy`). Needs herdr ≥ 0.7.0; ships
  prebuilt binaries for macOS Apple Silicon / Linux x86_64, else builds via Cargo
  (Rust already present for muster). No `config.toml` of its own required —
  patterns can be tuned via its plugin config dir or a project-local
  `.herdr-pluck.toml` if ever needed.

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

Two `[[keys.command]]` shell bindings break the focused pane out (herdr has no
built-in action for it, so they drive the `herdr pane move` CLI on
`$HERDR_ACTIVE_PANE_ID` — the keybinding-context var, not the pane-shell's
`HERDR_PANE_ID`; the herdr analogue of tmux `break-pane`): `prefix+t` →
`--new-tab`, `prefix+shift+t` → `--new-workspace`.

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
protocol in `$CLANK_HERDR_PROTOCOLS` (default `14`); an unrecognised protocol
degrades to tmux with a warning. Bump that env (or the default) after vetting a
new herdr release. herdr is pinned via `brew "herdr"` in `Brewfile-personal.tmpl`.

**Callers:** `~/.claude/commands/spawn.md` launches via `clank spawn`, verifies
via `clank state`, and tears down via `clank close`; `spawn-tmux` is now a thin
shim over `clank spawn --backend tmux`.

## Apply notes

`chezmoi apply` deploys these files and the `run_onchange` script reloads a
running herdr server via `herdr server reload-config`. To pick up keybinding
changes in an already-open herdr, reload from inside it (`prefix shift+r`) or run
`herdr server reload-config`.
