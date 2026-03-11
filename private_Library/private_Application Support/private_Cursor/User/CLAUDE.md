# Cursor Editor Config

After making changes to files in this directory, run `chezmoi apply` to deploy changes.

The `run_onchange_restore_extensions.sh.tmpl` script runs automatically when `data/cursor/extensions.txt` changes, installing Cursor extensions via `cursor --install-extension`.

## Worktree Apply

**Do not use `chezmoi apply` for extension changes from a worktree** — the `run_onchange_` checksum tracks `data/cursor/extensions.txt` and will pollute persistent state.

Instead, install extensions directly:

```sh
cat "$(git rev-parse --show-toplevel)/data/cursor/extensions.txt" | xargs -L 1 cursor --install-extension
```
