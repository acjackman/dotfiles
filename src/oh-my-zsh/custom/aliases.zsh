# Open/Edit
alias cdmp="cd $HOME/Dropbox/Dump"
alias editor_new="subl -n"
alias hconfig="editor_new ~/.hammerspoon ~/.hammerspoon/init.lua"
alias zshconfig="editor_new ~/.dotfiles/src/oh-my-zsh/custom ~/.zshrc ~/.zshrc_local"
alias dotfiles="editor_new ~/.dotfiles"
alias awsconfig="editor_new ~/.aws ~/.aws/config"

# Command Shortcuts
alias bi="brew install"
alias bci="brew cask install"
alias dcmp="docker-compose"
alias pwhich="pyenv which"
alias gtower='gittower git rev-parse --show-toplevel'

# Actions
alias o=open
alias sn="subl -n"
alias gitsweep="git branch --merged | egrep -v '(^\*|master|dev.*|stg|prod|develop|release/.*)' | xargs git branch -d && git remote | xargs git remote prune && echo 'Branches Remaining: ' && git --no-pager branch | head -n 20"
alias gitoverwrite="git add . && git commit --amend --no-edit && git psf"
alias awswhoami="aws sts get-caller-identity"
alias pyclean="find . -name '*.py[c|o]' -o -name __pycache__ -exec rm -rf {} +"
alias flashkb="wally-cli ~/Downloads/$(ls -t ~/Downloads | head -1)"
alias lspath="tr ':' '\n' <<< \"$PATH\""
alias sublhost="sudo subl -nw /etc/hosts && sudo killall -HUP mDNSResponder"
alias sshfingerprint="ssh-keygen -l -E md5 -f"

# Utilities
alias count_unique='cut -f 1 | sort | uniq -c'
