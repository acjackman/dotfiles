# Shared PATH (POSIX, also sourced by bash) — edit there, not here.
# In .zprofile so all login shells (interactive and non-interactive) get the
# correct PATH, e.g. tools like `claude` in .command files.
source "$HOME/.config/shell/path.sh"

# OrbStack completions (zsh-only half of the OrbStack setup)
[[ -d "$HOME/.orbstack/bin" ]] && fpath+=(/Applications/OrbStack.app/Contents/MacOS/../Resources/completions/zsh)
