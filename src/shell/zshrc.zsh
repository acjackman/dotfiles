# Based on https://github.com/iloveitaly/dotfiles/tree/master

# =============
# Completion
# =============

# forces zsh to realize new commands
zstyle ':completion:*' completer _oldlist _expand _complete _match _ignored _approximate

# matches case insensitive for lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending

# rehash if command not found (possibly recently installed)
zstyle ':completion:*' rehash true

# speed https://coderwall.com/p/9fksra/speed-up-your-zsh-completions
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# force completion generation for more obscure commands
zstyle :plugin:zsh-completion-generator   programs ncdu tre

# =============
# fzf-tab config
# =============

# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'

# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# menu if nb items > 2
zstyle ':completion:*' menu select=2

# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# don't show fzf unless there are more than 4 items
# zstyle ':fzf-tab:*' ignore false 4

# =============
# Shell Options
# man: zshoptions
# =============

setopt interactive_comments
setopt prompt_subst
setopt extended_glob            # Allow extended matchers like ^file, etc
setopt long_list_jobs
setopt auto_cd
setopt menu_complete            # Auto pick a menu match

# Set history behavior
# setopt share_history            # Share history across session
# setopt inc_append_history       # Dont overwrite history, add new entries immediately
setopt nosharehistory
setopt noincappendhistory
setopt extended_history         # Also record time and duration of commands.
setopt hist_expire_dups_first   # Clear duplicates when trimming internal hist.
setopt hist_find_no_dups        # Dont display duplicates during searches.
setopt hist_ignore_dups         # Ignore consecutive duplicates.
setopt hist_ignore_space        # Ignore commands prefixed with space
setopt hist_reduce_blanks       # Remove superfluous blanks.
setopt hist_save_no_dups        # Omit older commands in favor of newer ones.

# =============
# Evals
# =============
for brew_path in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
  if [[ -x "$brew_path" ]]; then
    eval "$($brew_path shellenv)"
    break
  fi
done

# if ! command -v python &> /dev/null
# then
#   export PATH="$PATH:$(brew --prefix python)/libexec/bin"
# fi


# avoid installation via brew, this is not a supported installation method and breaks
# some directory structure assumptions that exist across the plugin ecosystem.
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Scripts
export PATH="$PATH:$HOME/.local/bin" # pipx
export PATH="$PATH:$HOME/.local/share/jackman/bin" # personal scripts

# asdf setup
# export PATH="$PATH:${ASDF_DIR:-$HOME/.asdf}/bin"
# Not running default install, instead place shims at the end of path
# ASDF_FORCE_PREPEND=no . "${ASDF_DIR:-$HOME/.asdf}/asdf.sh"
export PATH="$PATH:${ASDF_DIR:-$HOME/.asdf}/shims:${ASDF_DIR:-$HOME/.asdf}/bin"
source "${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc"

# TODO https://github.com/zdharma/zinit/issues/173#issuecomment-537325714
# Load ~/.exports, ~/.aliases, ~/.functions and ~/.zshrc_local
# ~/.zshrc_local can be used for settings you don’t want to commit
for file in exports aliases functions zshrc_local; do
  local file="$HOME/.$file"
  [ -e "$file" ] && source "$file"
done

# Autoload personal functions
() {
    # https://stackoverflow.com/a/63661686
    # add our local functions dir to the fpath
    local funcs="${XDG_CONFIG_HOME:-${HOME}/.config}/zsh/functions"

    # FPATH is already tied to fpath, but this adds
    # a uniqueness constraint to prevent duplicate entries
    typeset -TUg +x FPATH=$funcs:$FPATH fpath

    # Now autoload them
    if [[ -d $funcs ]]; then
        autoload ${=$(cd "$funcs" && echo *)}
    fi
}

source ~/.zsh_plugins

# ===========
# Keybindings
# ===========
# open up current command in EDITOR, ctrl+x then ctrl+e
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# ===========
# Misc Config
# ===========

# https://til.hashrocket.com/posts/7evpdebn8g-remove-duplicates-in-zsh-path
typeset -U path

# # https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/misc.zsh
# autoload -Uz url-quote-magic
# zle -N self-insert url-quote-magic

# =======================================
# zsh-autosuggest & bracketed-paste-magic
# =======================================
# DISABLE_MAGIC_FUNCTIONS=true

# ===========
# Word Definition
# ===========
# http://mikebian.co/fixing-word-navigation-in-zsh/
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>/ '$'\n'
autoload -Uz select-word-style
select-word-style normal
zstyle ':zle:*' word-style unspecified
