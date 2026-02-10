#!/usr/bin/env zsh

pushd "$HOME" || exit

# Check if Homebrew is installed
if [ ! -f "$(which brew)" ]; then
  echo 'Installing homebrew'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Enable homebrew for the remainder of the script
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo 'homebrew already installed'
fi

# Change default shell
if [ ! $0 = "-zsh" ]; then
  echo 'Changing default shell to zsh'
  chsh -s /bin/zsh
else
  echo 'Already using zsh'
fi

brew tap homebrew/bundle # Install Homebrew Bundle
brew install chezmoi 1password 1password-cli gum

while [[ ! op whoami > /dev/null ]]; do
  echo "1Password is not signed in, please signin. Press any key to continue"
done

chezmoi init --apply --verbose https://github.com/acjackman/dotfiles.git
