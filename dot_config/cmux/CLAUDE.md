# cmux

AI agent terminal built on Ghostty. Manages multiple coding agents with vertical tabs, split panes, embedded browser, and socket API.

## Config Location

- **Terminal settings**: Inherited from Ghostty config (`dot_config/ghostty/`)
- **App shortcuts**: Stored in macOS defaults (`com.cmuxterm.app`), managed via `run_onchange_after_set-defaults.sh.tmpl`

## Keyboard Shortcuts

Custom split bindings (matching tmux):

| Action | Shortcut | tmux equivalent |
|--------|----------|-----------------|
| Split Down | Ctrl+- | prefix - |
| Split Right | Ctrl+Shift+\ | prefix \| |

## Shortcut Data Format

Shortcuts are hex-encoded JSON with keys: `shift`, `key`, `command`, `control`, `option`.

To encode a new shortcut:
```bash
echo -n '{"shift":false,"key":"-","command":false,"control":true,"option":false}' | xxd -p | tr -d '\n'
```

## Related Configs

- **Ghostty**: `dot_config/ghostty/` — terminal settings (fonts, theme, colors)
- **Aerospace**: `dot_config/aerospace/aerospace.toml` — workspace `T` rule
- **Leader Key**: `dot_config/leader-key/config.toml` — `t > c` launch binding
- **Karabiner**: `data/karabiner/karabiner.edn` — excluded from "Simultaneous jk" rule
- **Brewfile**: `dot_config/homebrew/Brewfile-base` — `cask "cmux"`
