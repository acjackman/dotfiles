#!/bin/bash
# One-time move of copies saved under the old, scattered layout into
# ~/.local/state/dotfiles/replaced/<subsystem>/ (see ,doctor-dotfiles).
# Runs before files are updated, so nothing in an exact dir is lost first.
set -uo pipefail
state="${XDG_STATE_HOME:-$HOME/.local/state}"
root="$state/dotfiles/replaced"

move_dir_contents() { # <old dir> <subsystem>
  [ -d "$1" ] || return 0
  mkdir -p "$root/$2"
  find "$1" -mindepth 1 -maxdepth 1 -exec mv -n {} "$root/$2/" \;
  rmdir "$1" 2>/dev/null
}
move_glob() { # <subsystem> <old file>... — drops the trailing .bak
  local sub="$1"; shift
  for f in "$@"; do
    [ -e "$f" ] || continue
    mkdir -p "$root/$sub"
    b="$(basename "$f")"
    mv -n "$f" "$root/$sub/${b%.bak}"
  done
}

move_dir_contents "$state/agent-skills-backups" agent-skills
move_dir_contents "$state/tuna-config-backups" tuna
move_glob sesh "$HOME"/.config/sesh/sesh.toml.*.bak
move_glob codex "$HOME"/.config/codex/config.toml.*.bak
exit 0
