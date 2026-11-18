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

query="${1-}"

dedup="awk '!seen[substr(\$0, index(\$0, \" \") + 1)]++'"
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
[[ -n "$query" ]] && fzf_cmd+=(--query "$query")

session="$(
  sesh list --icons --hide-attached 2>/dev/null | awk '!seen[substr($0, index($0, " ") + 1)]++' | "${fzf_cmd[@]}" 2>/dev/null
)" || exit 0

if [[ -n "$session" ]]; then
  # Strip icon prefix if present (sesh --icons prepends "<icon> ")
  # Paths from fd start with / ~ or . and have no icon to strip
  if [[ "$session" == /* || "$session" == ~* || "$session" == .* ]]; then
    session_name="$session"
  else
    session_name="${session#* }"
  fi

  # Only try to reuse an existing Ghostty window when the session actually
  # has attached tmux clients — that proves a window is displaying it.
  # Without this guard a substring match on the window title (e.g. a path
  # containing "infra") can false-positive, focus the wrong window, and
  # close the picker without ever attaching.
  attached_clients=$(tmux list-clients -t "=$session_name" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$attached_clients" -gt 0 ]]; then
    window_id=$(aerospace list-windows --all 2>/dev/null \
      | awk -F ' \\| ' -v sess="$session_name" '$2 ~ /Ghostty/ && $3 ~ " " sess "$" {print $1; exit}')

    if [[ -n "$window_id" ]]; then
      aerospace focus --window-id "$window_id"
      exit 0
    fi
    # Clients attached but no window found (e.g. embedded/detached client) —
    # fall through to sesh connect which will create a second attachment.
  fi

  sesh connect "$session_name"
fi
