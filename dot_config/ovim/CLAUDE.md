# ovim Config

[ovim](https://github.com/tonisives/ovim) provides system-wide vim keybindings and a neovim edit popup on macOS.

## File Locations

ovim has a split config layout:

| File | Chezmoi Source | Deploy Target | Purpose |
|------|---------------|---------------|---------|
| `settings.yaml` | `data/ovim/settings.yaml` | `~/Library/Application Support/ovim/settings.yaml` | Main settings (via `run_onchange_` script) |
| `domain-filetypes.yaml` | `dot_config/ovim/domain-filetypes.yaml` | `~/.config/ovim/domain-filetypes.yaml` | Per-app filetype for edit popup |
| `terminal-launcher.sh` | `dot_config/ovim/executable_terminal-launcher.sh` | `~/.config/ovim/terminal-launcher.sh` | Custom launcher (also copied to App Support) |

- `~/Library/Application Support/ovim/domain-filetypes.yaml` is a **symlink** to `~/.config/ovim/domain-filetypes.yaml` (ovim reads from App Support via Rust's `dirs::config_dir()`)
- The `run_onchange_after_setup-ovim.sh.tmpl` in `private_Library/private_Application Support/ovim/` copies both `settings.yaml` and `terminal-launcher.sh` to `~/Library/Application Support/ovim/`

## Key Settings

- **`enabled`** — toggles in-place vim mode. Runtime-toggled by `,ovim-in-place` script; defaults to `true` in chezmoi
- **`use_custom_script: true`** — launcher script uses `#!/bin/zsh` so PATH is available for nvim
- **`clipboard_mode: true`** — uses Cmd+A/Cmd+C for text capture, more reliable for Electron apps
- **`terminal: alacritty`** — alacritty is used for the edit popup
- **`ignored_apps`** — apps where in-place mode is disabled (Ghostty)

## Related Configs

- **Sketchybar**: `plugins/ovim.sh` shows vim mode in center bar, reads `settings.yaml` for enabled state
- **Aerospace**: `aerospace.toml` floats both `org.alacritty` and `com.tonis.ovim`
- **Leader Key**: `u → v` runs `,ovim-in-place` to toggle in-place mode
- **Brewfile**: `tonisives/tap/ovim` and `alacritty` casks
- **PATH**: `~/.local/bin/ovim` symlinks to `/Applications/ovim.app/Contents/MacOS/ovim`

## CLI

```sh
ovim mode          # Get current mode (normal/insert/visual)
ovim toggle        # Toggle between insert and normal
ovim insert|normal|visual  # Set specific mode
```

Communicates via Unix socket at `~/Library/Caches/ovim.sock`.

## Adding Domain Filetypes

Edit `domain-filetypes.yaml` with bundle ID → filetype mappings:

```yaml
com.tinyspeck.slackmacgap: markdown
com.google.Chrome: html
```

Restart ovim after changes (`osascript -e 'quit app "ovim"' && open -a ovim`).
