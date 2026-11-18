#!/usr/bin/env bash
#
# Keep Rex's agent skill and SessionStart hook installed (`rex skill setup`).
# Runs on EVERY apply, like herdr's run_after_ensure-herdr-integrations.sh:
# a Rex upgrade or a regenerated settings file can drop them without anything
# in this repo changing. Silent unless it acts.
#
# Where setup writes, and why chezmoi doesn't fight it:
#   claude — skills/rex/SKILL.md plus a SessionStart hook in settings.json, for
#            ~/.claude AND each ~/.config/claude/profiles/*; the settings
#            generator keeps hooks it doesn't own.
#   codex, opencode, pi — skill in ~/.agents/skills/rex, i.e. inside the exact
#            ~/.config/agents/skills dir; .chezmoiignore lists it so apply
#            doesn't delete it. Codex's hook goes in $CODEX_HOME/hooks.json
#            (unmanaged).
# The skill is a stub that asks the installed rex CLI for its guide, so it
# never goes stale between Rex versions.
set -euo pipefail

rex="/Applications/Rex.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex"
[[ -x "$rex" ]] || exit 0

# Anything not "current" (or "unsupported" for agents without hooks) needs setup.
ensure() {
  local where="$1" missing
  missing="$("$rex" skill status --json 2>/dev/null |
    jq -r '.harnesses[] | select(.detected) | .id as $a | .items[]
           | select(.state != "current" and .state != "unsupported")
           | "\($a) \(.kind)"' 2>/dev/null)" || return 0
  [[ -z "$missing" ]] && return 0
  echo "rex: running skill setup${where:+ ($where)} — missing: $(echo $missing)"
  "$rex" skill setup >/dev/null ||
    echo "warning: rex skill setup failed${where:+ ($where)}" >&2
}

# Default pass targets ~/.claude even when apply runs inside a profile session.
unset CLAUDE_CONFIG_DIR
ensure ""

for dir in "$HOME/.config/claude/profiles"/*/; do
  [[ -d "$dir" ]] || continue
  CLAUDE_CONFIG_DIR="${dir%/}" ensure "profile $(basename "$dir")"
done
