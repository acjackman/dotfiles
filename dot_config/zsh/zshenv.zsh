export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export COOKIECUTTER_CONFIG="${XDG_CONFIG_HOME}/cookiecutter/cookiecutter.yaml"

export GOKU_EDN_CONFIG_FILE="${XDG_CONFIG_HOME}/karabiner/karabiner.edn"

export CODEX_HOME="${XDG_CONFIG_HOME}/codex"

# Leader Key shims — sourced by all zsh shells (login, interactive, or plain)
export PATH="$PATH:$HOME/.config/leader-key/shims"
