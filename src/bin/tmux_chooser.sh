#!/bin/sh
# shellcheck disable=SC2207

# from https://cedaei.com/posts/ideas-from-my-dev-setup-always-tmux/

# Pickup hoembrew command with no config
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    PATH="$PATH:/opt/homebrew/bin"
fi

tmux new-session -A -D -s main
