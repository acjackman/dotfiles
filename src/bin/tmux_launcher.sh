#!/bin/sh
# shellcheck disable=SC2207

# from https://cedaei.com/posts/ideas-from-my-dev-setup-always-tmux/
#
export SHELL="/bin/zsh"

# Pickup hoembrew command with no config
if [[ -x "/opt/homebrew/bin/tmux" ]]; then
  export PATH="$PATH:/opt/homebrew/bin"
fi
if [[ -x "/usr/local/bin/tmux" ]]; then
  export PATH="$PATH:/usr/local/bin"
fi

if [[ -x "/opt/homebrew/bin/tmux" ]] || [[ -x "/usr/local/bin/tmux" ]]; then
  no_of_terminals=$(tmux list-sessions | wc -l)
  if [[ "$no_of_terminals" == "0" ]]; then
    exec tmux new-session -A -D -s main
  else
    exec tmux new-session -A -D -s $(($no_of_terminals + 1))
  fi
fi

# No tmux found, falling back to local shell
exec $SHELL
