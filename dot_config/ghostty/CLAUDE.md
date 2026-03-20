# Ghostty / cmux Config

Ghostty is the primary terminal emulator. cmux is a Ghostty-based terminal for managing AI coding agents — it reads the same Ghostty config files.

## Files

| File | Purpose |
|------|---------|
| `config.tmpl` | Main Ghostty config (chezmoi template) |
| `executable_ghostty-sesh` | Script to launch Ghostty with sesh session picker |
| `executable_ghostty-sesh-cmd` | Helper for ghostty-sesh |

## cmux

cmux (`com.cmuxterm.app`) inherits all Ghostty settings from this config. It adds workspaces, vertical tabs, split panes, an embedded browser, and a socket API for automation.

- **CLI**: `cmux` (installed via Homebrew at `/opt/homebrew/bin/cmux`)
- **Socket**: `~/Library/Application Support/cmux/cmux.sock`
- **Env vars**: `CMUX_WORKSPACE_ID`, `CMUX_SURFACE_ID`, `CMUX_SOCKET_PATH` (auto-set in cmux terminals)

## Related Configs

- **Aerospace**: `dot_config/aerospace/aerospace.toml` — cmux assigned to workspace `T`
- **Leader Key**: `dot_config/leader-key/config.toml` — `t > c` launches cmux
- **Karabiner**: `data/karabiner/karabiner.edn` — cmux excluded from "Simultaneous jk" rule
