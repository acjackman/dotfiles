export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# TODO: set ZDOTDIR

# Configure Homebrew
# See https://docs.brew.sh/Manpage#environment
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_AUTO_UPDATE=1

# Configure asdf
export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME:-${HOME}/.local/config}/asdf/asdfrc"
