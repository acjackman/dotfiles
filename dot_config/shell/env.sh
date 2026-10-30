# Shared environment — sourced by zsh (~/.zshenv) and bash (~/.bashrc).
# POSIX sh only: no zsh/bash-specific syntax. Keep side-effect free and fast;
# zshenv runs for every zsh, including scripts.

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export COOKIECUTTER_CONFIG="${XDG_CONFIG_HOME}/cookiecutter/cookiecutter.yaml"
export GOKU_EDN_CONFIG_FILE="${XDG_CONFIG_HOME}/karabiner/karabiner.edn"
export CODEX_HOME="${XDG_CONFIG_HOME}/codex"

# Homebrew — see https://docs.brew.sh/Manpage#environment
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_BUNDLE_FILE_GLOBAL="${XDG_CONFIG_HOME}/homebrew/Brewfile-machine"

export SPACECTL_SKIP_STACK_PROMPT='true'
export NOTI_DEFAULT="slack"

# Claude Code runs its Bash tool in bash rather than the login shell; agents
# write bash, and zsh's differences (nomatch, word splitting) trip them up.
# Homebrew bash, not /bin/bash 3.2.
[ -x /opt/homebrew/bin/bash ] && export CLAUDE_CODE_SHELL=/opt/homebrew/bin/bash

# Tuna shims — in env (not path.sh) so every shell gets them, login or not.
# Lets combo-mode bindings invoke brain-* as plain commands.
case ":$PATH:" in
  *":$HOME/.config/tuna/shims:"*) ;;
  *) export PATH="$PATH:$HOME/.config/tuna/shims" ;;
esac
