# Shared PATH — sourced by zsh (~/.zprofile) and bash (~/.bashrc).
# POSIX sh only. Lives in zprofile, not zshenv, because macOS /etc/zprofile
# runs path_helper after zshenv and would reorder anything set there.

# Homebrew — first, so everything below can use $HOMEBREW_PREFIX
for brew_path in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
  if [ -x "$brew_path" ]; then
    eval "$("$brew_path" shellenv)"
    break
  fi
done
unset brew_path

# OrbStack — PATH must precede Homebrew so docker resolves to OrbStack
[ -d "$HOME/.orbstack/bin" ] && export PATH="$HOME/.orbstack/bin:$PATH"

# Golang — GOPATH/bin prepended so locally-installed Go tools win over Homebrew shims.
# $HOMEBREW_PREFIX/opt rather than `brew --prefix`, which costs a subprocess per shell.
export GOROOT="$HOMEBREW_PREFIX/opt/go/libexec"
export GOPATH="$HOME/.local/go"
export PATH="${GOPATH}/bin:$PATH:${GOROOT}/bin"

# Rust
export PATH="$PATH:$HOME/.cargo/bin"

# Python
if ! command -v python >/dev/null 2>&1; then
  export PATH="$PATH:$HOMEBREW_PREFIX/opt/python/libexec/bin"
fi

# Scripts
export PATH="$HOME/.local/bin:$PATH" # pipx and other things put stuff here
export PATH="$PATH:$HOME/.local/share/jackman/bin" # personal scripts
[ -d "$HOME/.dotfiles-local/bin" ] && export PATH="$PATH:$HOME/.dotfiles-local/bin"

# Application Bins
export PATH="$PATH:$HOME/.config/emacs/bin" # doom emacs
[ -d "/Applications/Antigravity.app/" ] && export PATH="$PATH:$HOME/.antigravity/antigravity/bin"
[ -d "/Applications/Obsidian.app" ] && export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
[ -d "$HOME/.t3/bin" ] && export PATH="$PATH:$HOME/.t3/bin" # T3 Code CLI
# Rex CLI — the app bundle's stable copy (dir holds only `rex`), not the
# versioned RexServer/Versions/<n>/ path that changes on every update
[ -d "/Applications/Rex.app/Contents/Helpers/Rex Server.rex/Contents/MacOS" ] && export PATH="$PATH:/Applications/Rex.app/Contents/Helpers/Rex Server.rex/Contents/MacOS"

# Drop duplicates (first occurrence wins) — a shell started from another
# shell inherits PATH and re-runs everything above.
PATH="$(printf '%s' "$PATH" | awk -v RS=: -v ORS=: '!seen[$0]++' | sed 's/:$//')"
export PATH
