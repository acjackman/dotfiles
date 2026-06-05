# macOS System Settings

This directory holds chezmoi-managed settings that aren't tied to a specific
app — system-wide `defaults` writes, symbolic-hotkey overrides, and other
macOS-level state. Nothing here deploys to `~/.config/macos/`; the directory
is purely a chezmoi source location, and `run_onchange_*` scripts execute on
apply.

## Files

| File | Purpose |
|------|---------|
| `run_onchange_darwin-defaults.sh.tmpl` | Mathiasbynens-style system defaults (Finder, Dock, Safari, etc.) |
| `run_onchange_after_set-hotkeys.sh.tmpl` | Symbolic-hotkey overrides — disable shortcuts that collide with Tuna / AeroSpace |

## Symbolic hotkeys — adding/changing entries

Settings live in `~/Library/Preferences/com.apple.symbolichotkeys.plist` and
are keyed by stable but undocumented numeric IDs. Use the `set_hotkey`
helper in `set-hotkeys.sh.tmpl`:

```bash
# Disable Apple's default for an ID without rewriting the binding:
set_hotkey 34 0

# Disable AND fix the binding (use when capturing user-customized state):
set_hotkey 64 0 32 49 1048576
#          │  │  │  │  └── modifier mask (cmd = 1048576)
#          │  │  │  └───── virtual key code (49 = space)
#          │  │  └──────── character code (32 = space; 65535 for "any")
#          │  └─────────── enabled (0 = off, 1 = on)
#          └────────────── symbolic hotkey ID
```

### Modifier mask cheatsheet

Bit-OR these to combine:

| Modifier | Value      | Bit  |
|----------|------------|------|
| shift    | 131072     | 1<<17 |
| ctrl     | 262144     | 1<<18 |
| opt      | 524288     | 1<<19 |
| cmd      | 1048576    | 1<<20 |
| fn / Fn-key flag | 8388608 | 1<<23 |

Common combinations seen in this script:
- `262144`   = ctrl
- `524288`   = opt
- `786432`   = opt+ctrl
- `1048576`  = cmd
- `1572864`  = cmd+opt
- `8650752`  = fn+ctrl (used by F-key and arrow-key bindings)

### Common symbolic hotkey IDs

| ID | Default binding | Action |
|----|-----------------|--------|
| 32 | ctrl+↑ | Mission Control: All windows |
| 33 | ctrl+↓ | Mission Control: App Exposé |
| 34 | — | Show Desktop |
| 35 | — | Dashboard |
| 44 | — | Show Help menu |
| 60 | ctrl+space | Select previous input source |
| 61 | opt+ctrl+space | Select next input source |
| 64 | cmd+space | Show Spotlight search |
| 65 | cmd+opt+space | Show Spotlight window |
| 79 | ctrl+← | Move focus to Space Left |
| 81 | ctrl+→ | Move focus to Space Right |
| 118 | ctrl+1 | Switch to Desktop 1 |
| 119 | ctrl+2 | Switch to Desktop 2 |
| 160 | — | Launchpad |
| 175 | — | Show Notification Center |
| 179 | cmd+ctrl+space | Emoji & Symbols |
| 184 | cmd+shift+5 | Screenshot capture menu |

A fuller community-maintained reference lives at [rderik's macOS hotkey list](https://gist.github.com/rderik/8003d8f02f4569e44dc0bb22a30be6f8).

### Finding the binding for a hotkey you set in the UI

1. Open System Settings → Keyboard → Keyboard Shortcuts.
2. Toggle or set the shortcut.
3. Inspect the result:

   ```bash
   defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys
   ```

4. Copy the `enabled` value and `parameters` tuple into a `set_hotkey` line.

## Re-running after macOS upgrades

macOS upgrades silently re-enable some of the shortcuts this script disables —
most painfully `ctrl+space` (input-source switching, ID 60), which steals the
tmux prefix. Because `run_onchange_` only re-fires when the script's rendered
content changes, `set-hotkeys.sh.tmpl` embeds the current OS version via
`{{ "{{ output \"sw_vers\" \"-productVersion\" }}" }}` + `-buildVersion` in a
comment near the top. Any macOS update (major, point, or build) changes that
string, so the overrides re-apply automatically on the next `/apply`. Keep that
marker line in place.

## Applying

`/apply` will re-fire both scripts when their content changes. After apply,
log out + back in for symbolic-hotkey changes to fully release (the
`killall cfprefsd` in the script flushes the cache, but some shortcuts
remain captured until the WindowServer session restarts).
