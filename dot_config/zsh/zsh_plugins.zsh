# -*- mode: sh -*-
# plugin location: `~/.local/share/zinit/plugins`

# Based on https://github.com/iloveitaly/dotfiles/tree/master

###########################
# oh-my-zsh plugins
###########################
# in some environments, we may not be able to install svn
# if type svn &> /dev/null; then
#   zinit svn wait lucid for \
# fi

# autopair must be loaded before syntax highlight
zinit wait lucid for \
  OMZ::lib/functions.zsh \
  OMZ::lib/termsupport.zsh \
  hlissner/zsh-autopair \
  OMZ::plugins/safe-paste

###########################
# Completion Setup
# similar to copycat, but using the native search so it's fast (https://github.com/tmux-plugins/tmux-copycat/tree/master)
###########################

export ZVM_INIT_MODE=sourcing

# zicompinit runs `compinit` to generate completions
# important to load suggestions *after* zsh-completions
#   - fzf/key-bindings: sets up reverse-i via fzf
#   - fzf-tab: load order is important, must go last
#   - forgit needs _git to be loaded in order for the additional src to work, which is why we zicompinit
# TODO https://github.com/felipec/git-completion/issues/8
# blockf ver"zinit-fixed" as"completion" nocompile mv'git-completion.zsh -> _git' iloveitaly/git-completion \
zinit wait lucid for \
  mafredri/zsh-async \
  zpm-zsh/zsh-better-npm-completion \
  'https://github.com/junegunn/fzf/blob/master/shell/completion.zsh' \
  pick"shell/kubectl_fzf.plugin.zsh" bonnefoa/kubectl-fzf \
  atinit'zicompinit' atpull'zinit creinstall .' wfxr/forgit \
  blockf atpull'zinit creinstall  .' zsh-users/zsh-completions \
  RobSis/zsh-completion-generator \
  atload'_zsh_autosuggest_start' zsh-users/zsh-autosuggestions \
  atuinsh/atuin \
  pick"worktrunk.plugin.zsh" ~/.config/zsh/plugins \
  atinit"zicompinit; zicdreplay" zsh-users/zsh-syntax-highlighting \
  Aloxaf/fzf-tab \
  iloveitaly/zsh-github-cli \
  depth:1 jeffreytse/zsh-vi-mode \
  pick"kubectl-completion.plugin.zsh" ~/.config/zsh/plugins

# must be loaded after syntax completion
zinit load zsh-users/zsh-history-substring-search

# experimental
#   - zsh-256color: configures env for 256 color support
#   - colors: sets aliases for some colors and most styles via '$c'
#   - lib/spectrum.zsh: 'spectrum_ls' alias to visually inspect colors
zinit wait'1' lucid for \
  djui/alias-tips \
  chrissicool/zsh-256color \
  zpm-zsh/colors \
  OMZ::lib/spectrum.zsh \
  ajeetdsouza/zoxide

# binaries installed via zinit
#   - git-fuzzy: 'git fuzzy' for interactive git commit cli
#   - ports: 'ports ls' to inspect what ports are open
#   - universalarchive: 'ua' for easily unarchiving everything from the command line`
zinit wait'2' lucid for \
  as"program" pick"bin/git-fuzzy" bigH/git-fuzzy \
  caarlos0/ports \
  OMZ::plugins/universalarchive

# must load last
zinit ice depth=1
zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# avoid loading the builtin git completions
# https://mikebian.co/git-completions-tooling-on-the-command-line/
rm ${HOMEBREW_PREFIX}/share/zsh/site-functions/_git 2> /dev/null

# function don't get completions by default, aliases need to be manually assigned
# zicompdef fdd=fd
# zicompdef rgg=rg
