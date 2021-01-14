# Open/Edit
alias cdmp="cd $HOME/Dropbox/Dump"
alias editor_new="subl -n"
alias hconfig="editor_new ~/.hammerspoon ~/.hammerspoon/init.lua"
alias zshconfig="editor_new ~/.dotfiles/src/oh-my-zsh/custom ~/.zshrc ~/.zshrc_local"
alias dotfiles="editor_new ~/.dotfiles"
alias awsconfig="editor_new ~/.aws ~/.aws/config"
alias enw="emacs -nw"

# Command Shortcuts
alias bi="brew install"
alias bci="brew cask install"
alias dcmp="docker-compose"
alias dcud="docker-compose up -d"
alias pwhich="pyenv which"
alias gtower='gittower $(git rev-parse --show-toplevel)'
alias aws2='/usr/local/bin/aws'
alias aws-cli=aws2

# Actions
alias o=open
alias sn="subl -n"
alias tower='gittower $(git home)'
alias gitsweep="git branch --merged | egrep -v '(^\*|master|dev.*|stg|prod|develop|release/.*)' | xargs git branch -d && git remote | xargs git remote prune && echo 'Branches Remaining: ' && git --no-pager branch | head -n 20"
alias gitoverwrite="git commit --amend --no-edit && git psf"
alias awswhoami="aws-cli sts get-caller-identity"
alias pyclean="find . -name '*.py[c|o]' -o -name __pycache__ -exec rm -rf {} +"
alias flashkb='wally-cli "$(ls -t ~/Downloads/*.hex | head -1)"'
alias lspath="tr ':' '\n' <<< \"$PATH\""
alias sublhost="sudo subl -nw /etc/hosts && sudo killall -HUP mDNSResponder"
alias sshfingerprint="ssh-keygen -l -E md5 -f"

# Utilities
alias count_unique='cut -f 1 | sort | uniq -c'

# Navigation
alias pd="popd"

## Moving up
alias x="clear && ls"
alias ..="cd .. && clear && ls"
alias ...="cd ../.. && clear && ls"
alias ....="cd ../../.. && clear && ls"
alias .....="cd ../../../.. && clear && ls"

## Shortcuts to common directories
alias dbox="pushd ~/Dropbox && clear && ls"
alias dboxn="pushd ~/Dropbox/Notes && clear && ls -1 | tail -r | grep -v -E '(media|^Z.*|Notes & Settings|.*csv$)' | head -10 && echo '...'"
alias dev="pushd ~/Development && clear && echo */ | sed 's:/::g' "
