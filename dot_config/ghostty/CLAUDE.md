# Ghostty / cmux Config

Ghostty is the primary terminal emulator. cmux is a Ghostty-based terminal for managing AI coding agents — it reads the same Ghostty config files.

## Files

| File | Purpose |
|------|---------|
| `config.tmpl` | Main Ghostty config (chezmoi template) |
| `executable_ghostty-sesh` | Script to launch Ghostty with sesh session picker |
| `executable_ghostty-sesh-cmd` | Helper for ghostty-sesh |

## cmux

cmux (`com.cmuxterm.app`) inherits all Ghostty settings from this config. It has its own config directory at `dot_config/cmux/` for app-specific defaults (keyboard shortcuts, etc.).
