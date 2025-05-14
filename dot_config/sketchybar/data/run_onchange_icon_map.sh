#!/bin/bash

set -e

wget -q -O icon_map.json.new https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.32/icon_map.json
if [ -s icon_map.json.new ]; then
  mv icon_map.json.new icon_map.json
else
  rm icon_map.json.new
fi
