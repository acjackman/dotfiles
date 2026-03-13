# zsh plugin so it can be loaded dynamically after compinit
if command -v wt >/dev/null 2>&1 || [[ -n "${WORKTRUNK_BIN:-}" ]]; then
  eval "$(wt config shell init zsh)"

  # Wrap wt to use pushd instead of cd for directory switching,
  # preserving the directory stack for easy navigation with popd.
  eval "$(functions wt | sed 's/source "$directive_file"/source <(sed "s|^cd |pushd -q |" "$directive_file")/')"
fi
