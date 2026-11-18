# kubectl completion, generated lazily on first <Tab> (kubectl-fzf wraps it).
# `kubectl completion zsh` costs ~40ms per shell, so the real _kubectl is only
# built when first requested. Registered via _comps directly because zinit
# shadows compdef while this plugin loads.

if command -v kubectl &> /dev/null; then
  _kubectl_lazy() {
    unfunction _kubectl_lazy
    source <(kubectl completion zsh)   # defines _kubectl and compdefs it
    _kubectl "$@"
  }
  _comps[kubectl]=_kubectl_lazy
fi
