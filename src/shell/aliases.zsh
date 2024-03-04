# -*- mode: sh -*-
alias enw="emacs -nw"
alias te="emacs.sh -nw"
alias e="nvim"


alias ls='exa -l --group-directories-first'
alias j='z'
alias jjj='zi'
alias tree='tre --limit 3'
#
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

# git
alias g=git
alias gitsweep="git branch --merged | egrep -v '(^\*|master|dev.*|stg|prod|develop|release/.*)' | xargs git branch -d && git remote | xargs git remote prune && echo 'Branches Remaining: ' && git --no-pager branch | head -n 20"
alias git-hew-wip="git branch | sed '/^\*/d' | sed '/^\+/d' | xargs git branch -D"

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

# Commons
alias dotfiles="cd ~/.dotfiles && e"
alias notes="cd ~/notes && e"
