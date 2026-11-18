# CleanShot X

Screenshot and screen recording utility for macOS.

## Config Location

All settings are stored in macOS defaults: `defaults read pl.maketheweb.cleanshotx`

Managed via `run_onchange_after_set-defaults.sh.tmpl` in this directory.

## Keyboard Shortcuts

Global shortcuts (replace macOS default screenshot shortcuts):

| Action                        | Shortcut    |
| ----------------------------- | ----------- |
| Capture Area                  | Cmd+Shift+4 |
| Capture Fullscreen            | Cmd+Shift+3 |
| All-in-One Capture            | Cmd+Shift+6 |
| OCR (Text Recognition)        | Cmd+Shift+1 |
| OCR with Line Breaks          | Cmd+Shift+2 |
| Quick Access: Restore         | Cmd+Shift+7 |
| Quick Access: Restore Last    | Cmd+Shift+5 |

Shortcuts are stored as binary-encoded JSON in defaults (`LAVA*` keys) with `carbonModifiers` and `carbonKey` fields.

## Shortcut Data Format

To add/modify shortcuts in the defaults script, encode the JSON as hex:

```bash
echo -n '{"carbonModifiers":768,"carbonKey":21}' | xxd -p | tr -d '\n'
```

Common modifier values: 256=Cmd, 512=Shift, 768=Cmd+Shift, 2048=Opt, 4096=Ctrl

Key codes use macOS virtual key codes (18=1, 19=2, 20=3, 21=4, 22=5, 23=6, 26=7).

## Related Configs

- **Homebrew**: `dot_config/homebrew/Brewfile-base` — `cask "cleanshot"`
- **Aerospace**: `dot_config/aerospace/aerospace.toml` — floating window rule for annotation editor
## Applying from Worktrees

No special instructions — the defaults script runs normally via chezmoi apply.
