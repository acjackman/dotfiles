# kubectl completion setup for kubectl-fzf
# This is sourced after compinit is complete so compdef is available

if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
fi
