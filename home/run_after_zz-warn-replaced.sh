#!/bin/bash
# Remind on every apply while replaced copies wait for review. Runs every time
# (not onchange) and stays silent when there's nothing. Details: ,doctor-dotfiles
root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/replaced"
[ -d "$root" ] || exit 0
subs=""
for sub in "$root"/*/; do
  [ -d "$sub" ] || continue
  n=$(find "$sub" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
  [ "$n" -gt 0 ] && subs="$subs $(basename "$sub")($n)"
done
[ -n "$subs" ] && echo "dotfiles: replaced copies waiting for review:$subs — run ,doctor-dotfiles" >&2
exit 0
