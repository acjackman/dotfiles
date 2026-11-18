# Ghostty / cmux Config

Ghostty is the primary terminal emulator. cmux is a Ghostty-based terminal for managing AI coding agents — it reads the same Ghostty config files.

## Files

| File | Purpose |
|------|---------|
| `config.tmpl` | Main Ghostty config (chezmoi template) |
| `executable_ghostty-herdr` | Opens a new Ghostty window running herdr — the default new-window launcher: Hammerspoon Cmd+N (Ghostty focused), the Hyper+T fallback when Ghostty has no windows, and Tuna `t n`. Each window attaches as another client to the same herdr session. |
| `executable_ghostty-herdr-cmd` | Helper run inside the new window; execs `herdr` |
| `executable_ghostty-sesh` | Script to launch Ghostty with sesh session picker (Cmd+Shift+N / Tuna `t s`) |
| `executable_ghostty-sesh-cmd` | Helper for ghostty-sesh |

## cmux

cmux (`com.cmuxterm.app`) inherits all Ghostty settings from this config. It has its own config directory at `dot_config/cmux/` for app-specific defaults (keyboard shortcuts, etc.).
