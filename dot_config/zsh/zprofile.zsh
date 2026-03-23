# Homebrew — in .zprofile so all login shells (interactive and non-interactive)
# get the correct PATH. This ensures tools like `claude` are found in .command
# files and other non-interactive login shells.
for brew_path in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
  if [[ -x "$brew_path" ]]; then
    eval "$($brew_path shellenv)"
    break
  fi
done

# Golang
export GOROOT="$(brew --prefix golang)/libexec"
export GOPATH="$HOME/.local/go"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

# Rust
export PATH="$PATH:$HOME/.cargo/bin"

# Python
if ! command -v python &> /dev/null; then
  export PATH="$PATH:$(brew --prefix python)/libexec/bin"
fi

# Scripts
export PATH="$HOME/.local/bin:$PATH" # pipx and other things put stuff here
export PATH="$PATH:$HOME/.local/share/jackman/bin" # personal scripts
[ -d "$HOME/.dotfiles-local/bin" ] && export PATH="$PATH:$HOME/.dotfiles-local/bin"

# Application Bins
export PATH="$PATH:$HOME/.config/emacs/bin" # doom emacs
[ -d "/Applications/Antigravity.app/" ] && export PATH="$PATH:$HOME/.antigravity/antigravity/bin"
[ -d "/Applications/Obsidian.app" ] && export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# Leader Key shims — short scripts that make the cheatsheet readable
export PATH="$PATH:$HOME/.config/leader-key/shims"
