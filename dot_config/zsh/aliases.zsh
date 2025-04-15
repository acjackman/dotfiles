# -*- mode: sh -*-
alias enw="emacs -nw"
alias e="$VISUAL"

alias ls='eza --group-directories-first'
alias ll='eza --group-directories-first -lah'
alias tree='tre --limit 3'

alias ,clear='clear && if [ -v TMUX ]; then; tmux clear-history; fi'

alias trim='tr -d "\n"'

# Command Shortcuts
alias dcmp="docker-compose"
alias o=open

alias rgf="rg --files-with-matches"

# Tools
alias lspath='tr ":" "\n" <<< "$PATH"'
alias lspathu='tr ":" "\n" <<< "$PATH" | awk "!seen[\$0]++"'

alias sshfingerprint="ssh-keygen -l -E md5 -f"
alias count_unique='cut -f 1 | sort | uniq -c'
alias json2yaml="yq eval -P"
alias yaml2json="yq eval --tojson"

alias ,show-aliases="export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1"

alias k9s='TERM=xterm-256color k9s'
alias ,k9s='k9s --context=$(yq -r '"'"'.contexts[] | .name'"'"' ~/.kube/config | fzf --layout reverse --height=10% --border) --namespace=all'
alias k9ss=',k9s'

# git
alias g=git
alias lg=lazygit
alias gitsweep="git branch --merged | egrep -v '(^\*|master|dev.*|stg|prod|develop|release/.*)' | xargs git branch -d && git remote | xargs git remote prune && echo 'Branches Remaining: ' && git --no-pager branch | head -n 20"
alias git-hew-wip="git branch | sed '/^\*/d' | sed '/^\+/d' | xargs git branch -D"

alias ,gwa="git worktree add"
alias ,gwrm='g w remove $(pwd) && cd $(dirname $(g home))'

# github
alias ,opr="gh pr view --web"
alias ,gho='gh repo view --web'
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

# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfat='terraform apply -target'
alias tfaaa='terraform apply --auto-approve'
alias tffmt='terraform fmt -check -recursive'

# Spacelift
alias splogin='unset SPACELIFT_API_TOKEN; spacectl whoami > /dev/null || spacectl profile login; export SPACELIFT_API_TOKEN=$(spacectl profile export-token)'

# Config
alias chezmoi-local="chezmoi -S ~/.local/share/chezmoi-local --config ~/.config/chezmoi-local/chezmoi.toml"
alias ,c='chezmoi'
alias ,cl='chezmoi-local'
function ,ce() (
  pushd ~/.local/share/chezmoi > /dev/null
  chezmoi edit $@
)
function ,cle() (
  pushd ~/.local/share/chezmoi-local > /dev/null
  chezmoi-local edit $@
)

# Tmux
alias ,t='~/.config/tmux/tmux_launcher.sh'

# Common projects
alias dotfiles="tat dotfiles"
alias notes="tat notes"

# Jump points
alias ,jump-git-home='[[ "$(git rev-parse --is-inside-work-tree)" == "true" ]] && pushd "$( git rev-parse --show-toplevel )" > /dev/null'
alias ,jg=,jump-git-home
alias ,jump-git-worktree='pushd "$( git worktree list | sed '"'"'/\.bare/d'"'"' | fzf | awk '"'"'{print $1}'"'"' )" > /dev/null'
alias ,jgw=,jump-git-worktree
alias ,jump-git-bare='pushd "$( git worktree list --porcelain | awk '"'"'/^worktree /{p=$2} /^bare$/{print p}'"'"' )/../" > /dev/null'
alias ,jgb=,jump-git-bare
alias ,jc="pushd ~/.local/share/chezmoi > /dev/null"
alias ,jcl="pushd ~/.local/share/chezmoi-local > /dev/null"
alias ,jn="pushd ~/notes > /dev/null"
