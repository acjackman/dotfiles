# Mise Config

The `run_onchange_after_mise-up.sh` script runs automatically when `data/mise/config.toml` changes, updating mise tool versions via `mise update`.

## Worktree Apply

**Do not use `chezmoi apply` for mise config from a worktree** — the `run_onchange_` checksum tracks `data/mise/config.toml` and will pollute persistent state.

Instead, run mise directly:

```sh
mise update
```
