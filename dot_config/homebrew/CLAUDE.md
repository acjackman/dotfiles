# Homebrew Config

After making changes to Brewfiles in this directory, run `chezmoi apply` to deploy changes.

Scripts:
- `run_onchange_darwin-install-packages.sh.tmpl` - runs automatically when any `Brewfile-*` changes, installing packages via `brew bundle`
- `run_onchange_uninstall.sh.tmpl` - handles package uninstallation
