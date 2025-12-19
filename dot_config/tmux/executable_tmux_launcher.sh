#!/bin/bash
# shellcheck disable=SC2207

# from https://cedaei.com/posts/ideas-from-my-dev-setup-always-tmux/
#
set -euo pipefail

# Guard: Ensure SHELL is set
export SHELL="${SHELL:-/bin/zsh}"

# Guard: Verify shell exists
if [[ ! -x "$SHELL" ]]; then
  echo "Warning: $SHELL not found, falling back to /bin/bash" >&2
  export SHELL="/bin/bash"
fi

# Pickup homebrew command with no config
if [[ -x "/opt/homebrew/bin/tmux" ]]; then
  export PATH="$PATH:/opt/homebrew/bin"
fi
if [[ -x "/usr/local/bin/tmux" ]]; then
  export PATH="$PATH:/usr/local/bin"
fi

# Guard: Check if tmux is available
if ! command -v tmux &>/dev/null; then
  echo "Warning: tmux not found in PATH, starting shell" >&2
  exec "$SHELL"
fi

# Guard: Check if required commands exist
if ! command -v sesh &>/dev/null; then
  echo "Warning: sesh not found, starting tmux directly" >&2
  exec tmux
fi

if ! command -v fzf-tmux &>/dev/null && ! command -v fzf &>/dev/null; then
  echo "Warning: fzf not found, starting tmux directly" >&2
  exec tmux
fi

# Main launcher with error handling
if [[ -x "/opt/homebrew/bin/tmux" ]] || [[ -x "/usr/local/bin/tmux" ]]; then
  # from https://github.com/joshmedeski/sesh?tab=readme-ov-file#tmux--fzf
  session="$(
    sesh list --icons --hide-attached 2>/dev/null | fzf-tmux \
      --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
      --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
      --bind 'tab:down,btab:up' \
      --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
      --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
      --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
      --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
      --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
      --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons --hide-attached)' \
      --preview-window 'right:55%' \
      --preview 'sesh preview {}' 2>/dev/null
  )" || {
    # Fallback: If fzf was cancelled, just exit
    exit 0
  }
  # Guard: Check if session was selected
  if [[ -n "$session" ]]; then
    sesh connect "$session" || {
      echo "Failed to connect to session" >&2
      exit 1
    }
  else
    # No session selected, exit
    exit 0
  fi
else
  # No tmux found, falling back to local shell
  exec "$SHELL"
fi
