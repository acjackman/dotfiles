#!/bin/bash
# ~/.agents/skills is a chezmoi-managed symlink to ~/.config/agents/skills
# (see .chezmoidata/agent-skills.yaml). If a real directory is there — a
# machine where `npx skills add -g` ran before this was managed — move it and
# the npx global lock aside instead of letting apply trip over or clobber it.
set -euo pipefail

dir="$HOME/.agents/skills"
[ -d "$dir" ] && [ ! -L "$dir" ] || exit 0

backup="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/replaced/agent-skills/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
mv "$dir" "$backup/skills"
[ -f "$HOME/.agents/.skill-lock.json" ] && mv "$HOME/.agents/.skill-lock.json" "$backup/"
echo "agent-skills: moved unmanaged ~/.agents/skills to $backup (review: ,doctor-dotfiles)" >&2
