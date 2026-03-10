#!/bin/sh

OVIM="/Applications/ovim.app/Contents/MacOS/ovim"
SETTINGS="$HOME/Library/Application Support/ovim/settings.yaml"

# Hide if ovim isn't running or in-place mode is disabled
ENABLED=$(grep '^enabled:' "$SETTINGS" 2>/dev/null | head -1 | awk '{print $2}')
if [ "$ENABLED" != "true" ]; then
  sketchybar --set "$NAME" drawing=off
  return 0 2>/dev/null || exit 0
fi

MODE=$("$OVIM" mode 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$MODE" ]; then
  sketchybar --set "$NAME" drawing=off
  return 0 2>/dev/null || exit 0
fi

case "$MODE" in
  normal)
    ICON=""
    LABEL="NORMAL"
    COLOR="0xff89b4fa" # blue
    ;;
  insert)
    ICON=""
    LABEL="INSERT"
    COLOR="0xffa6e3a1" # green
    ;;
  visual)
    ICON="󰒅"
    LABEL="VISUAL"
    COLOR="0xffcba6f7" # mauve
    ;;
  *)
    ICON=""
    LABEL="$MODE"
    COLOR="0xffffffff"
    ;;
esac

sketchybar --set "$NAME" \
  drawing=on \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="$LABEL" \
  label.color="$COLOR"
