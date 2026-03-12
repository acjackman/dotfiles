# sesh completion setup
# This is sourced after compinit is complete so compdef is available

if command -v sesh &> /dev/null; then
  source <(sesh completion zsh)
fi

# Complete ,t (sesh session launcher) with session names
_,t_complete() {
  local -a sessions
  local session_list
  session_list=$(sesh list -t -c --icons 2>/dev/null)
  if [[ -n "$session_list" ]]; then
    while IFS= read -r line; do
      sessions+=("${line}")
    done <<< "$session_list"
    _describe 'sesh sessions' sessions
  else
    _message 'no sessions found'
  fi
}
# Register directly in _comps, bypassing zinit's compdef wrapper
# which queues calls that may never be replayed after zicdreplay.
_comps[,t]=_,t_complete
