# -*- mode: sh -*-
# plugin location: `~/.local/share/zinit/plugins`

# oh-my-zsh plugins
# in some environments, we may not be able to install svn
if type svn &> /dev/null; then
  zinit svn wait lucid for \
    OMZ::plugins/extract
fi

# NOTE the public iterm zsh integration is broken
# https://github.com/decayofmind/zsh-iterm2-utilities
zinit ice depth"1" \
  pick"shell_integration/zsh" \
  sbin"utilities/*" if"[[ $+ITERM_PROFILE ]]"
zinit load gnachman/iTerm2-shell-integration

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

# zicompinit runs `compinit` to generate completions
# important to load suggestions *after* zsh-completions
#   - fzf/key-bindings: sets up reverse-i via fzf
#   - fzf-tab: load order is important, must go last
#   - forgit needs _git to be loaded in order for the additional src to work, which is why we zicompinit
# TODO https://github.com/felipec/git-completion/issues/8
# blockf ver"zinit-fixed" as"completion" nocompile mv'git-completion.zsh -> _git' iloveitaly/git-completion \
zinit wait lucid for \
  mafredri/zsh-async \
  redxtech/zsh-asdf-direnv \
  zpm-zsh/zsh-better-npm-completion \
  'https://gist.githubusercontent.com/iloveitaly/4eac0f4ddb3f8162f95fa3ed6f123a06/raw/91af07681dcb1bd863f1922526d6287debd10a80/1password.zsh' \
  'https://gist.githubusercontent.com/iloveitaly/a79ffc31ef5b4785da8950055763bf52/raw/4140dd8fa63011cdd30814f2fbfc5b52c2052245/github-copilot-cli.zsh' \
  'https://gist.githubusercontent.com/iloveitaly/043d91a2968597fe601673664b124dd3/raw/f79dd08a352f9dfde17ba22d345e8e1f87ac3c57/orbctl.zsh' \
  'https://gist.githubusercontent.com/iloveitaly/ebd80140aaa4d8183b558adddb06b809/raw/fc23843bd07b3665233b8d74d0030b8ffff290dd/pack.plugin.zsh' \
  'https://github.com/iloveitaly/dolt/blob/zsh-plugin/dolt.plugin.zsh' \
  'https://github.com/junegunn/fzf/blob/master/shell/completion.zsh' \
  'https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh' \
  as'completion' blockf OMZ::plugins/ripgrep/_ripgrep \
  atinit'zicompinit' atpull'zinit creinstall .' src'completions/git-forgit.zsh' wfxr/forgit \
  blockf atpull'zinit creinstall  .' zsh-users/zsh-completions \
  RobSis/zsh-completion-generator \
  atinit"zicompinit; zicdreplay" zdharma/fast-syntax-highlighting \
  atload'_zsh_autosuggest_start' zsh-users/zsh-autosuggestions \
  Aloxaf/fzf-tab \
  iloveitaly/zsh-github-cli \
  atload"zpcdreplay" atclone"./zplug.zsh" atpull"%atclone" g-plane/pnpm-shell-completion

# TODO conflicts with fzf-tab
# marlonrichert/zsh-autocomplete

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
rm $(brew --prefix)/share/zsh/site-functions/_git 2> /dev/null

# function don't get completions by default, aliases need to be manually assigned
# zicompdef fdd=fd
# zicompdef rgg=rg