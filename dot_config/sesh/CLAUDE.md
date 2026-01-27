# Sesh Config

After making changes to files in `sessions.d/`, run `chezmoi apply` to deploy changes.

The `run_onchange_after_merge-sesh-sessions.sh.tmpl` script runs automatically when any `sessions.d/*.toml` file changes. It concatenates all TOML files into `sesh.toml`, validating the TOML before writing and creating a backup of the previous config.

Note: `sesh.toml` is generated and ignored by chezmoi. Edit files in `sessions.d/` instead.
