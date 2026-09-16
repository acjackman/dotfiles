# -*- mode: sh -*-
# plugin location: `~/.local/share/zinit/plugins`
#
# Completion ordering rules (compinit has already run in zshrc.zsh.tmpl):
#   1. `#compdef` files are only honoured at compinit time, from the dump. A
#      plugin's _foo files must reach fpath *before* that: zinit creinstall
#      symlinks them into its completions dir (blockf keeps the plugin from
#      touching fpath itself). Adding fpath entries here is too late.
#   2. Scripts that *call* compdef (eval "$(tool completion zsh)") must run
#      after compinit. zinit shadows `compdef` while a plugin loads and queues
#      the call, so the last plugin of each turbo batch carries
#      atload'zicdreplay' (atload runs with the shadow off) to replay them.
#      Local plugins that must not depend on a replay write _comps[cmd] directly.
#   3. Anything that adds new _foo files (zinit update, mise/brew installs)
#      needs the dump rebuilt: ,zsh-cleanup-completions.
# Verified 2026-09-15 by diffing the full _comps table against the previous
# layout: identical apart from the removed plugins, and `z` (zoxide) is now
# registered where it previously fell through a missing replay.
#
# Pruned 2026-09-15 (zero uses in 90 days of history, nothing else referenced
# them): forgit, git-fuzzy, ports, universalarchive, alias-tips, zsh-256color,
# zpm-zsh/colors, OMZ spectrum, zsh-better-npm-completion,
# zsh-completion-generator, zsh-github-cli, zsh-async.

###########################
# oh-my-zsh plugins
###########################

# autopair must be loaded before syntax highlight
zinit wait lucid for \
  OMZ::lib/functions.zsh \
  OMZ::lib/termsupport.zsh \
  hlissner/zsh-autopair \
  OMZ::plugins/safe-paste

###########################
# Completion & line editing
###########################

export ZVM_INIT_MODE=sourcing

# Load order matters:
#   - fzf/key-bindings: sets up reverse-i via fzf
#   - zsh-completions: blockf so it doesn't touch fpath; creinstall symlinks
#     its _files into zinit's completions dir, which is in fpath already
#   - fast-syntax-highlighting after autopair
#   - fzf-tab must load after syntax highlighting
#   - the last entry replays queued compdefs (zicdreplay)
zinit wait lucid for \
  'https://github.com/junegunn/fzf/blob/master/shell/completion.zsh' \
  pick"shell/kubectl_fzf.plugin.zsh" bonnefoa/kubectl-fzf \
  blockf atpull'zinit creinstall .' zsh-users/zsh-completions \
  atload'_zsh_autosuggest_start' zsh-users/zsh-autosuggestions \
  atuinsh/atuin \
  pick"worktrunk.plugin.zsh" ~/.config/zsh/plugins \
  zdharma-continuum/fast-syntax-highlighting \
  Aloxaf/fzf-tab \
  depth:1 jeffreytse/zsh-vi-mode \
  pick"kubectl-completion.plugin.zsh" ~/.config/zsh/plugins \
  pick"k9s.plugin.zsh" ~/.config/zsh/plugins \
  pick"sesh-completion.plugin.zsh" ~/.config/zsh/plugins \
  atload'zicdreplay' pick"homebrew-token.plugin.zsh" ~/.config/zsh/plugins

# must be loaded after syntax highlighting
zinit load zsh-users/zsh-history-substring-search

zinit wait'1' lucid atload'zicdreplay' for \
  ajeetdsouza/zoxide

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
# zicompdef ,t=,t
