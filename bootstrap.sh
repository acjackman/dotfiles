#!/bin/bash
cd $HOME
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
.dotfiles/install

# Install applications
brew bundle install --global

# Install Poetry;
if [[ -f "$HOME/.poetry/bin/poetry" ]]; then
  echo 'Poetry already installed'
else
  curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python
fi


pipx install black nox
