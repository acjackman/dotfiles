alias zshconfig="subl -n ~/.dotfiles/src/oh-my-zsh/custom ~/.zshrc ~/.zshrc_local"
alias hconfig="subl -n ~/.hammerspoon ~/.hammerspoon/init.lua"
alias dcmp="docker-compose"
alias gitsweep="git branch --merged | egrep -v '(^\*|master|dev.*|stg|prod|develop|release/.*)' | xargs git branch -d && git remote | xargs git remote prune && echo 'Branches Remaining: ' && git --no-pager branch | head -n 20"
alias pyclean="find . -name '*.py[c|o]' -o -name __pycache__ -exec rm -rf {} +"
alias lspath="tr ':' '\n' <<< \"$PATH\""
alias pwhich="pyenv which"
alias flashkb="wally-cli ~/Downloads/$(ls -t ~/Downloads | head -1)"
alias bi="brew install"
alias bci="brew cask install"
alias count_unique='cut -f 1 | sort | uniq -c'
alias awswhoami="aws sts get-caller-identity"

