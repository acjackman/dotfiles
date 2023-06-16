#!/usr/bin/env zsh

cd "$HOME" || exit

export OMZDIR="$HOME/.oh-my-zsh"
export DOTFILES_DIR="$HOME/.dotfiles"

# Check if Homebrew is installed
if [ ! -f "$(which brew)" ]; then
  echo 'Installing homebrew'
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  # Enable homebrew for the remainder of the script
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo 'homebrew already installed'
fi

brew tap homebrew/bundle # Install Homebrew Bundle
brew install mas

# Change default shell
if [ ! $0 = "-zsh" ]; then
  echo 'Changing default shell to zsh'
  chsh -s /bin/zsh
else
  echo 'Already using zsh'
fi

# Clone Dotfiles repo
if [[ ! -d "$DOTFILES_DIR" ]]; then
  git clone --recurse-submodules -j8 https://github.com/acjackman/dotfiles $DOTFILES_DIR
else
  echo 'dotfiles already cloned'
fi

# Install dotfiles
.dotfiles/src/bin/dotfiles-install

# Install applications
brew bundle install --global

# Start Yabai
command -v yabai 2>&1 >/dev/null && FOUND_YABAI=1 || FOUND_YABAI=0
if [[ $FOUND_YABAI -eq 1 ]]; then
  yabai --start-service
fi
unset FOUND_YABAI
