#!/bin/bash

OMZDIR="$HOME/.oh-my-zsh"
DOTFILES_DIR="$HOME/.dotfiles"

# Check if Homebrew is installed
if [ ! -f "`which brew`" ]; then
  echo 'Installing homebrew'
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo 'homebrew already installed'
fi
brew tap homebrew/bundle  # Install Homebrew Bundle

# Check if oh-my-zsh is installed
if [ ! -d "$OMZDIR" ]; then
  echo 'Installing oh-my-zsh'
  /bin/sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
else
  echo 'oh-my-zsh already installed'
fi

# Change default shell
if [ ! $0 = "-zsh"]; then
  echo 'Changing default shell to zsh'
  chsh -s /bin/zsh
else
  echo 'Already using zsh'
fi

# Clone Dotfiles repo
if [[ ! -d "$DOTFILES_DIR" ]]; then
    git clone https://github.com/acjackman/dotfiles $DOTFILES_DIR
else
    echo 'dotfiles already cloned'
fi

# Install dotfiles
.dotfiles/install
