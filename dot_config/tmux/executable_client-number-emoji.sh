#!/bin/bash
# Return a number emoji for this client's position among all clients attached to the session.
# Usage: client-number-emoji.sh <session> <client_tty>

session="$1"
client_tty="$2"
emojis=(1️⃣ 2️⃣ 3️⃣ 4️⃣ 5️⃣ 6️⃣ 7️⃣ 8️⃣ 9️⃣)

index=$(tmux list-clients -t "$session" -F '#{client_created} #{client_tty}' | sort -n | grep -n "$client_tty" | cut -d: -f1)

if [ "$index" -ge 1 ] 2>/dev/null && [ "$index" -le 9 ]; then
  echo "${emojis[$((index - 1))]}"
else
  echo "${index:-👻}"
fi
