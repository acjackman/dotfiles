# Open/Edit
alias cdmp="cd $HOME/Dropbox/Dump"
alias editor_new="subl -n"
alias hconfig="editor_new ~/.hammerspoon ~/.hammerspoon/init.lua"
alias zshconfig="editor_new ~/.dotfiles/src/oh-my-zsh/custom ~/.dotfiles/src/bin ~/.zshrc ~/.zshrc_local"
alias dotfiles="editor_new ~/.dotfiles"
alias awsconfig="editor_new ~/.aws ~/.aws/config"
alias enw="emacs -nw"

# Command Shortcuts
alias bi="brew install"
alias bci="brew cask install"
alias dcmp="docker-compose"
alias dcud="docker-compose up -d"
alias pwhich="pyenv which"
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
alias lspath='tr ":" "\n" <<< "$PATH"'
alias lspathu='tr ":" "\n" <<< "$PATH" | awk "!seen[\$0]++"'
alias sublhost="sudo subl -nw /etc/hosts && sudo killall -HUP mDNSResponder"
alias sshfingerprint="ssh-keygen -l -E md5 -f"
alias pyv="poetry version | awk '{print \$2}'"
alias pyv-master="git show master:pyproject.toml | yj -t | jq -r '.tool.poetry.version'"
alias pyv-major='[[ -z "$(git status --porcelain)" ]] && poetry version major && git add pyproject.toml && git commit -m "bump major version to $(pyv)"'
alias pyv-minor='[[ -z "$(git status --porcelain)" ]] && poetry version minor && git add pyproject.toml && git commit -m "bump minor version to $(pyv)"'
alias pyv-patch='[[ -z "$(git status --porcelain)" ]] && poetry version patch && git add pyproject.toml && git commit -m "bump patch version to $(pyv)"'

# Utilities
alias count_unique='cut -f 1 | sort | uniq -c'
alias json2yaml="yq eval -P"
alias yaml2json="yq eval --tojson"


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
alias notes="pushd ~/Notes && clear && ls -1 | tail -r | grep -v -E '(media|^Z.*|Notes & Settings|.*csv$)' | head -10 && echo '...'"
alias dev="pushd ~/Development && clear && echo */ | sed 's:/::g' "
