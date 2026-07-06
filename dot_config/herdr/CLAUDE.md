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

## Apply notes

`chezmoi apply` deploys these files and the `run_onchange` script reloads a
running herdr server via `herdr server reload-config`. To pick up keybinding
changes in an already-open herdr, reload from inside it (`prefix shift+r`) or run
`herdr server reload-config`.
