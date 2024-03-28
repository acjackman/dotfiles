# -*- mode: sh -*-
alias enw="emacs -nw"
alias e="nvim"

alias ls='eza --group-directories-first'
alias ll='eza --group-directories-first -lah'
alias tree='tre --limit 3'

alias ,clear='clear && if [ -v TMUX ]; then; tmux clear-history; fi'

# Command Shortcuts
alias dcmp="docker-compose"
alias o=open
alias tf=terraform

# Tools
alias lspath='tr ":" "\n" <<< "$PATH"'
alias lspathu='tr ":" "\n" <<< "$PATH" | awk "!seen[\$0]++"'

alias sshfingerprint="ssh-keygen -l -E md5 -f"
alias count_unique='cut -f 1 | sort | uniq -c'
alias json2yaml="yq eval -P"
alias yaml2json="yq eval --tojson"

alias ,show-aliases="export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1"

# git
alias g=git
alias lg=lazygit
alias gitsweep="git branch --merged | egrep -v '(^\*|master|dev.*|stg|prod|develop|release/.*)' | xargs git branch -d && git remote | xargs git remote prune && echo 'Branches Remaining: ' && git --no-pager branch | head -n 20"
alias git-hew-wip="git branch | sed '/^\*/d' | sed '/^\+/d' | xargs git branch -D"

alias ,gwa="git worktree add"

# github
alias ,opr="gh pr view --web"
alias ,ghpro="gh pr view --web"
alias ,ghprn="gh pr view --json number --jq number"

# fancier ping
alias ping='prettyping --nolegend'

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
alias whois="whois -h whois-servers.net"

# Flush Directory Service cache
alias flushdns="sudo killall -HUP mDNSResponder"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en0' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en0 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Python
alias pip='python -m pip'

# Cloud
alias awswhoami="aws-cli sts get-caller-identity"

# Common projects
alias dotfiles="tat dotfiles"
alias notes="tat notes"

# Jump points
alias ,jg='pushd $(git rev-parse --show-toplevel) > /dev/null'
alias ,jc="pushd ~/.dotfiles > /dev/null"
alias ,jn="pushd ~/notes > /dev/null"
