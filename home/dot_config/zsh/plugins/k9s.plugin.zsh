# k9s context picker - records the actual k9s command in history
_k9s_context_picker_widget() {
  local context
  context=$(yq -r '.contexts[] | .name' ~/.kube/config | fzf --layout reverse --height=10% --border)
  if [[ -n "$context" ]]; then
    BUFFER="k9s --context=$context --namespace=all"
    zle accept-line
  else
    zle reset-prompt
  fi
}
zle -N _k9s_context_picker_widget
bindkey '^xk' _k9s_context_picker_widget  # Ctrl+x then k to launch k9s picker
