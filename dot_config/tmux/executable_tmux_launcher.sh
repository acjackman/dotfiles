#!/bin/bash
# shellcheck disable=SC2207

# Tmux session launcher using sesh for interactive session picking.
# Falls back to basic tmux if sesh/fzf are not available.

export SHELL="${SHELL:-/bin/zsh}"

# Pickup homebrew command with no config
if [[ -x "/opt/homebrew/bin/tmux" ]]; then
  export PATH="$PATH:/opt/homebrew/bin"
fi
if [[ -x "/usr/local/bin/tmux" ]]; then
  export PATH="$PATH:/usr/local/bin"
fi

if ! command -v tmux &>/dev/null; then
  echo "Warning: tmux not found in PATH, starting shell" >&2
  exec "$SHELL"
fi

# Fallback if sesh or fzf are not available
if ! command -v sesh &>/dev/null || ! command -v fzf-tmux &>/dev/null; then
  exec tmux new-session -A -s main
fi

dedup="awk '!seen[\$0]++'"
fzf_cmd=(fzf
  --no-sort --ansi --border-label ' sesh ' --prompt '⚡  '
  --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find'
  --bind 'tab:down,btab:up'
  --bind "ctrl-a:change-prompt(⚡  )+reload(sesh list --icons | $dedup)"
  --bind "ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons | $dedup)"
  --bind "ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons | $dedup)"
  --bind "ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons | $dedup)"
  --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)'
  --bind "ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons --hide-attached | $dedup)"
  --preview-window 'right:55%'
  --preview 'sesh preview {}'
)

session="$(
  sesh list --icons --hide-attached 2>/dev/null | awk '!seen[$0]++' | "${fzf_cmd[@]}" 2>/dev/null
)" || exit 0

if [[ -n "$session" ]]; then
  # Extract the session name by stripping the icon prefix (first field)
  session_name="${session#* }"

  # Check if a Ghostty window already has this session active
  window_id=$(aerospace list-windows --all 2>/dev/null \
    | awk -F ' \\| ' -v sess="$session_name" '$2 ~ /Ghostty/ && $0 ~ sess {print $1; exit}')

  if [[ -n "$window_id" ]]; then
    # Focus the existing window and exit (closing this picker window)
    aerospace focus --window-id "$window_id"
    exit 0
  fi

  sesh connect "$session"
fi
