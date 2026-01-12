# zsh plugin so it can be loaded dynamically after compinit
if command -v wt >/dev/null 2>&1 || [[ -n "${WORKTRUNK_BIN:-}" ]]; then
  eval "$(wt config shell init zsh)"
fi
