#!/usr/bin/env zsh

cd "$HOME" || exit

export OMZDIR="$HOME/.oh-my-zsh"
export DOTFILES_DIR="$HOME/.dotfiles"

# Ask for the administrator password upfront
sudo -n true || sudo -v

# Keep-alive: update existing `sudo` time stamp until script finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit

done 2>/dev/null &

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

if [ ! -f "/opt/jackman" ]; then
  sudo mkdir -p /opt/jackman
  sudo chown $(whoami) /opt/jackman
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


# Clone Dotfiles repo
if [[ ! -d "$HOME/.config/emacsp" ]]; then
  git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
  ~/.config/emacs/bin/doom install
else
  echo 'doom emacs already cloned'
fi


# Configure macos defaults
~/.dotfiles/src/macos

# Start Yabai
command -v yabai 2>&1 >/dev/null && FOUND_YABAI=1 || FOUND_YABAI=0
if [[ $FOUND_YABAI -eq 1 ]]; then
  yabai --start-service
fi
unset FOUND_YABAI
