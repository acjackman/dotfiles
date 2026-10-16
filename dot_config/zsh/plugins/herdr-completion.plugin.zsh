# herdr completion, generated lazily on first <Tab>.
# herdr is installed from its releases into ~/.local/bin and updates itself
# (dot_config/herdr/run_after_install-herdr.sh.tmpl), so there is no Homebrew
# _herdr in site-functions anymore. Generating at <Tab> time keeps completions
# in step with whatever binary `herdr update` last installed. Registered via
# _comps directly because zinit shadows compdef while this plugin loads.

if command -v herdr &> /dev/null; then
  _herdr_lazy() {
    unfunction _herdr_lazy
    source <(herdr completion zsh)   # defines _herdr and compdefs it
    _herdr "$@"
  }
  _comps[herdr]=_herdr_lazy
fi
