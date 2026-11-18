# sesh completion, generated lazily on first <Tab>.
# `sesh completion zsh` costs ~30ms per shell, so the real _sesh is only built
# when first requested. Registered via _comps directly because zinit shadows
# compdef while this plugin loads.

if command -v sesh &> /dev/null; then
  _sesh_lazy() {
    unfunction _sesh_lazy
    source <(sesh completion zsh)   # defines _sesh and compdefs it
    _sesh "$@"
  }
  _comps[sesh]=_sesh_lazy
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
_comps[,t]=_,t_complete
