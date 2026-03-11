# Alfred Preferences

After making changes to files in this directory, run `chezmoi apply` to deploy changes.

Scripts:
- `run_onchange_after_alfred-local-settings.sh.tmpl` - configures machine-specific Alfred settings (hotkeys, clipboard, appearance) in the local hash directory
- `run_onchange_after_install-workflows.sh.tmpl` - installs Alfred workflows

## Worktree Apply

The workflow install script's checksum tracks `data/alfred/workflows.yaml`. **Do not use `chezmoi apply` for this from a worktree** — it pollutes persistent state.

Instead, run the install script directly (it uses `{{ .chezmoi.sourceDir }}` internally, so set the config path manually):

```sh
# There is no simple manual workaround — the script uses chezmoi template variables.
# Either merge to main and apply, or accept the state pollution for testing.
```
