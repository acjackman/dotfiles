#!/bin/sh

FILE="$HOME/.ssh/config"
if [ ! -f "$FILE" ]; then
  echo >>$FILE <<EOF
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

Include ~/.ssh/1Password/config
EOF
fi
