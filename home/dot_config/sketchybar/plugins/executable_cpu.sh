#!/bin/sh

ICON="󰍛"
GREEN="0xffa6e3a1"
YELLOW="0xfff9e2af"
RED="0xfff38ba8"

PERCENTAGE="$(top -l 1 | grep -E "^CPU" | awk '{printf "%d", $3+$5}')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

if [ "$PERCENTAGE" -ge 80 ]; then
  COLOR="$RED"
elif [ "$PERCENTAGE" -ge 50 ]; then
  COLOR="$YELLOW"
else
  COLOR="$GREEN"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
