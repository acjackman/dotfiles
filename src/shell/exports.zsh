# -*- mode: sh -*-

# env config for compatibility with omz
export ZSH=${HOME}/.zsh
export ZSH_CACHE_DIR=${ZSH}/cache

# without this some CLI tools (gh cli, for instance) do not page contents
export PAGER=less

# Don’t clear the screen after quitting a manual page
export MANPAGER="less -FX"

# more powerful less config
# https://www.topbug.net/blog/2016/09/27/make-gnu-less-more-powerful/
export LESS='--quit-if-one-screen --ignore-case --status-column --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --tabs=4 --window=-4'

# Zsh alias

export ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="g e"
export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=0
export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_TEXT="Long version: "

# Emacs
if [[ -e "$HOME/.emacs.d/bin" ]]; then
  export PATH="$HOME/.emacs.d/bin:$PATH"
fi

if [[ -e "$HOME/${XDG_CONFIG_HOME:-.config}/emacs/bin" ]]; then
  export PATH="$HOME/${XDG_CONFIG_HOME:-.config}/emacs/bin:$PATH"
fi

# Editor
export VISUAL=nvim
export EDITOR="$VISUAL"

# Golang
export GOPATH="$HOME/.local/go"
export GOBIN="$HOME/.local/go/bin"
export PATH="$PATH:$GOBIN"
