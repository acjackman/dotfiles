#! /bin/bash

function show-header() {
  command -v gum &>/dev/null
  if [ $? -eq 0 ]; then
    gum style --border=double --align=left --padding "0 2" --width=75 $@
  else
    echo $@
  fi
}

# config.yml Checksum {{ include "data/mise/config.toml" | sha256sum }}
command -v mise &>/dev/null
if [ $? -eq 0 ]; then
  show-header "Mise"
  mise update && echo "Mise tools updated" || echo "Mise failed update"
fi

# Set llm key
# {{ if "personal" .extras}}
llm keys set anthropic --value $(op read --account jackman.1password.com "op://Private/Claude/api-keys/llm")
# {{ end }}
