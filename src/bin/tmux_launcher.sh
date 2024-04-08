#!/bin/sh
# shellcheck disable=SC2207

# from https://cedaei.com/posts/ideas-from-my-dev-setup-always-tmux/
#
export SHELL="/bin/zsh"

# Pickup hoembrew command with no config
if [[ -x "/opt/homebrew/bin/tmux" ]]; then
	export PATH="$PATH:/opt/homebrew/bin"
	exec /opt/homebrew/bin/tmux new-session -A -D -s main
fi

if [[ -x "/usr/local/bin/tmux" ]]; then
	export PATH="$PATH:/usr/local/bin"
	exec /usr/local/bin/tmux new-session -A -D -s main
fi

# No tmux found, falling back to local shell

exec $SHELL
