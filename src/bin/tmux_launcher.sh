#!/bin/bash
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
  sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null))
  if [[ "${#sessions[@]}" -eq 0 ]]; then
    exec tmux new-session -A -D -s main
  else
    next_id=1
    digit_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -E '^[0-9]+$')
    function exists() {
      echo $digit_sessions | tr " " "\n" | grep -F -q -x $1
    }
    while exists $next_id; do
      next_id=$(($next_id + 1))
    done

    # echo "Next id: $next_id"
    # read -r input
    exec tmux new-session -A -D -s $next_id
  fi
else
  # No tmux found, falling back to local shell
  exec $SHELL
fi
