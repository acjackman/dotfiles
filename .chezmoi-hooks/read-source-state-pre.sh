#!/bin/sh
# chezmoi hooks.read-source-state.pre (home/.chezmoi.toml.tmpl): runs before
# every command that reads the source state (apply, diff, status, re-add, ...).
set -e
# defaults-sync renders .tmpl files with a nested chezmoi; skip the hook there.
[ -n "$DEFAULTS_SYNC_RENDERING" ] && exit 0
here=$(dirname "$0")

"$here/../.install-password-manager.sh"

# Refresh ~/.local/state/dotfiles/defaults/*.toml from the live plists so chezmoi
# compares desired settings against what the apps have now. Never block chezmoi
# over it: a broken file is reported and the rest of the command goes on.
python3 -I "$here/defaults-sync.py" snapshot || true
