# Sesh Config

After making changes to TOML files under `~/.config/sesh/`, run `chezmoi apply` to deploy changes.

The `run_onchange_after_merge-sesh-sessions.sh.tmpl` script runs automatically when any `.toml` file under `~/.config/sesh/` changes. It finds all `.toml` files in subdirectories (e.g., `sessions.d/`, or any other subdirectory), sorts them by basename so numeric prefixes control order regardless of directory, validates the combined TOML, and writes `sesh.toml`. A backup of the previous config is created before overwriting.

Session TOML files must be in a subdirectory of `~/.config/sesh/` (any subdirectory works, not just `sessions.d/`). Files at the root level (like `sesh.toml` itself) are excluded automatically.

Note: `sesh.toml` is generated and ignored by chezmoi. Edit files in subdirectories instead.
