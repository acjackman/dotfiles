# Leader Key Config

After making changes to TOML files in this directory, run `chezmoi apply` to deploy changes.

The `run_onchange_after_generate_config.py.tmpl` script runs automatically when any `*.toml` file changes. It merges all TOML configs into `config.json` and restarts the Leader Key app to reload the configuration.

TOML files use a v2 map-based structure for easier merging. See the script for supported formats.
