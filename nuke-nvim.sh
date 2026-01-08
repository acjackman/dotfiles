#!/bin/bash

set -e

function show-header() {
  command -v gum &>/dev/null
  if [ $? -eq 0 ]; then
    gum style --border=double --align=left --padding "0 2" --width=75 "$@"
  else
    echo "$@"
  fi
}

function confirm() {
  command -v gum &>/dev/null
  if [ $? -eq 0 ]; then
    gum confirm "$@"
  else
    read -p "$@ (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
  fi
}

show-header "🗑️  Neovim Config Nuke & Reinstall"

echo "This will remove:"
echo "  - ~/.config/nvim"
echo "  - ~/.local/share/nvim"
echo "  - ~/.local/state/nvim"
echo "  - ~/.cache/nvim"
echo ""
echo "Then reinstall from chezmoi."
echo ""

if ! confirm "Are you sure you want to continue?"; then
  echo "Aborted."
  exit 1
fi

echo ""
show-header "Removing nvim directories..."

# Remove nvim config
if [ -d ~/.config/nvim ]; then
  echo "Removing ~/.config/nvim"
  rm -rf ~/.config/nvim
fi

# Remove nvim data
if [ -d ~/.local/share/nvim ]; then
  echo "Removing ~/.local/share/nvim"
  rm -rf ~/.local/share/nvim
fi

# Remove nvim state
if [ -d ~/.local/state/nvim ]; then
  echo "Removing ~/.local/state/nvim"
  rm -rf ~/.local/state/nvim
fi

# Remove nvim cache
if [ -d ~/.cache/nvim ]; then
  echo "Removing ~/.cache/nvim"
  rm -rf ~/.cache/nvim
fi

echo ""
show-header "Reinstalling from chezmoi..."

# Re-apply chezmoi config
chezmoi apply ~/.config/nvim

echo ""
show-header "✅ Done!"
echo "Your nvim config has been nuked and reinstalled."
echo "Plugins should be restored automatically on first nvim launch."
