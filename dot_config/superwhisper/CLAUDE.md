# SuperWhisper Config

Voice-to-text dictation tool with LLM reformatting. Bundle ID: `com.superduper.superwhisper`

## Config Location

All config is stored in macOS defaults (`com.superduper.superwhisper`). No file-based config.
Read current values: `defaults read com.superduper.superwhisper`

## Key Settings

- **Toggle recording**: Cmd+Option+Space (`KeyboardShortcuts_toggleRecording`)
- **Push to talk**: Right Command (`KeyboardShortcuts_pushToTalk`)
- **Launch on login**: enabled
- **Silence removal**: enabled
- **Mini recorder overlay**: always shown

## Related Configs

- **Aerospace** (`dot_config/aerospace/aerospace.toml`): Floating window rule for the recorder overlay
- **Brewfile** (`dot_config/homebrew/Brewfile-base`): Installed as `cask "superwhisper"`
