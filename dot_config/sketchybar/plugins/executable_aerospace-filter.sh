#!/bin/bash

# Toggles drawing on each space.<id> item so only workspaces with windows
# (plus the focused workspace) are visible. The aerospace-plugin binary
# creates one item per workspace; this script hides the empty ones.

set -eu

focused=$(aerospace list-workspaces --focused)

# Visible = (workspaces with windows) ∪ {focused}.
visible=$(
  {
    aerospace list-workspaces --monitor all --empty no
    printf '%s\n' "$focused"
  } | sort -u
)

# The aerospace-plugin binary creates space.<id> items lazily, so iterate
# only over items that actually exist in sketchybar.
existing=$(
  sketchybar --query bar \
    | python3 -c 'import json,sys; print("\n".join(i for i in json.load(sys.stdin).get("items",[]) if i.startswith("space.")))'
)

args=()
space_items=()
while IFS= read -r item; do
  [[ -z "$item" ]] && continue
  space_items+=("$item")
  ws=${item#space.}
  if grep -qxF "$ws" <<<"$visible"; then
    args+=(--set "$item" drawing=on)
  else
    args+=(--set "$item" drawing=off)
  fi
done <<<"$existing"

# Keep timing pinned to the right of the workspace icons. The aerospace-plugin
# creates space.<id> items lazily, so timing (added in sketchybarrc) ends up
# left of them by default — reorder on every event so new spaces don't push
# timing out of place.
if (( ${#space_items[@]} )); then
  args+=(--reorder "${space_items[@]}" timing)
fi

if (( ${#args[@]} )); then
  sketchybar "${args[@]}"
fi
