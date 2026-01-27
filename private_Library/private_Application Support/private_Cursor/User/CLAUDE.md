# Cursor Editor Config

After making changes to files in this directory, run `chezmoi apply` to deploy changes.

The `run_onchange_restore_extensions.sh.tmpl` script runs automatically when `data/cursor/extensions.txt` changes, installing Cursor extensions via `cursor --install-extension`.
