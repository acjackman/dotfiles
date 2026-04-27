#!/bin/sh

ICON="󰘚"
GREEN="0xffa6e3a1"
YELLOW="0xfff9e2af"
RED="0xfff38ba8"

FREE="$(memory_pressure | grep "System-wide memory free percentage:" | awk '{print $5}' | tr -d '%')"

if [ "$FREE" = "" ]; then
  exit 0
fi

PERCENTAGE=$((100 - FREE))

if [ "$PERCENTAGE" -ge 80 ]; then
  COLOR="$RED"
elif [ "$PERCENTAGE" -ge 60 ]; then
  COLOR="$YELLOW"
else
  COLOR="$GREEN"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
