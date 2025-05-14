#!/bin/bash

set -e

wget -q -O aerospace-plugin https://github.com/acjackman/sketchybar-aerospace-plugin/releases/download/v0.2.0/aerospace-plugin
chmod u+x aerospace-plugin
if xattr -p com.apple.quarantine aerospace-plugin &>/dev/null; then
  xattr -d com.apple.quarantine aerospace-plugin
fi
