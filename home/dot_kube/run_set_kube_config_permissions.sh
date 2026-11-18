#!/bin/sh

FILE="$HOME/.kube/config"
if [ -f "$FILE" ]; then
  if [ "$(stat -f "%OLp" "$FILE")" != "600" ]; then
    chmod 600 "$FILE"
  fi
fi
