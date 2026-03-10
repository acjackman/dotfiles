#!/bin/sh

OVIM="/Applications/ovim.app/Contents/MacOS/ovim"
SETTINGS="$HOME/Library/Application Support/ovim/settings.yaml"
GRAY="0xff6c7086" # overlay0

# Hide if ovim isn't running or in-place mode is disabled
ENABLED=$(grep '^enabled:' "$SETTINGS" 2>/dev/null | head -1 | awk '{print $2}')
if [ "$ENABLED" != "true" ]; then
  sketchybar --set "$NAME" drawing=off
  return 0 2>/dev/null || exit 0
fi

MODE=$("$OVIM" mode 2>/dev/null)
RED="0xfff38ba8" # red

if [ $? -ne 0 ] || [ -z "$MODE" ]; then
  sketchybar --set "$NAME" \
    drawing=on icon="󰀦" icon.color="$RED" \
    label="NOT RUNNING" label.color="$RED"
  return 0 2>/dev/null || exit 0
fi

# Check frontmost app
FRONT_APP=$(lsappinfo info -only bundleid "$(lsappinfo front)" 2>/dev/null | sed 's/.*"\(.*\)"/\1/' | tail -1)

# Terminal apps — ovim passes keys through
TERMINALS="org.alacritty com.mitchellh.ghostty"
for t in $TERMINALS; do
  if [ "$FRONT_APP" = "$t" ]; then
    sketchybar --set "$NAME" \
      drawing=on icon="" icon.color="$GRAY" \
      label="TERMINAL" label.color="$GRAY"
    exit 0
  fi
done

# Ignored apps from ovim config
if [ -n "$FRONT_APP" ] && sed -n '/^ignored_apps:/,/^[^ -]/p' "$SETTINGS" 2>/dev/null | grep -q "^- ${FRONT_APP}$"; then
  sketchybar --set "$NAME" \
    drawing=on icon="󰜺" icon.color="$GRAY" \
    label="DISABLED" label.color="$GRAY"
  exit 0
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
