# Neovim Config

After making changes to files in this directory, run `chezmoi apply` to deploy changes.

The `run_onchange_restore_nvim.sh.tmpl` script runs automatically when `data/nvim/lazy-lock.json` changes, restoring Neovim plugins via `nvim --headless "+Lazy! restore"`.

## Worktree Apply

**Do not use `chezmoi apply` to trigger plugin restore from a worktree** — the `run_onchange_` checksum tracks `data/nvim/lazy-lock.json` and will pollute persistent state.

Instead, restore plugins directly:

```sh
nvim --headless "+Lazy! restore" +qa
```
