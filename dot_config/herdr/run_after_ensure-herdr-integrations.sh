#!/usr/bin/env bash
#
# Keep herdr's agent integrations installed and current. Runs on EVERY apply
# (run_after_, not run_onchange_): a herdr upgrade bumps integration versions
# without touching anything in this repo, so there's no source hash to key on.
# Cheap when healthy — one `herdr integration status` per config dir, which only
# reads local files (no server needed) — and silent unless it acts.
#
# What integrations buy (see dot_config/herdr/CLAUDE.md, "Agent integrations"):
# session IDs so herdr resumes agent panes after a server restart, direct state
# reporting for pi/omp, and the session record herdr-bar (Claude transcript
# titles) and herdr-radar (activity timing) read.
#
# Where each one writes, and why chezmoi doesn't fight it:
#   pi/omp  — an extension file under ~/.pi / ~/.omp (unmanaged).
#   claude  — hooks/herdr-agent-state.sh plus a SessionStart entry in
#             settings.json; the settings generator keeps hooks it doesn't own.
#             Done for ~/.claude AND each ~/.config/claude/profiles/*.
#   codex   — herdr-agent-state.sh + hooks.json in $CODEX_HOME (unmanaged), and
#             `[features] hooks = true` in config.toml, which is GENERATED — so
#             that flag lives in dot_config/codex/exact_config.d/10-features.toml.
#   opencode — a plugin under ~/.config/opencode/plugins (unmanaged).
#   cursor  — herdr-agent-state.sh + hooks.json under ~/.cursor (unmanaged).
set -euo pipefail

command -v herdr >/dev/null 2>&1 || exit 0

# "<herdr integration target>:<CLI that must be on PATH for it to matter>".
# Plain list, not an associative array: stays bash-3.2 safe.
agents=(claude:claude codex:codex pi:pi omp:omp opencode:opencode cursor:cursor-agent)

# `herdr integration status` prints "<agent>: current (vN) (path)" when
# installed and up to date; anything else (not installed, outdated) needs an
# install, which is idempotent and upgrades in place.
ensure() {
  local agent="$1" where="$2" line
  line="$(herdr integration status 2>/dev/null | grep "^${agent}:" || true)"
  [[ "$line" == "${agent}: current "* ]] && return 0
  echo "herdr: installing ${agent} integration${where:+ ($where)} — was: ${line#*: }"
  herdr integration install "$agent" >/dev/null || \
    echo "warning: herdr integration install ${agent} failed${where:+ ($where)}" >&2
}

# Clear CLAUDE_CONFIG_DIR so the default pass targets ~/.claude even when apply
# runs from inside a Claude session (which exports it pointing at a profile —
# the default would then be skipped as "current" and silently rot).
unset CLAUDE_CONFIG_DIR

for pair in "${agents[@]}"; do
  agent="${pair%%:*}"
  command -v "${pair#*:}" >/dev/null 2>&1 || continue
  # omp's installer needs omp's own agent dir (created on first run).
  [[ "$agent" == omp && ! -d "$HOME/.omp/agent" ]] && continue
  ensure "$agent" ""
done

# Each Claude profile (CLAUDE_CONFIG_DIR) carries its own hooks + settings.json.
if command -v claude >/dev/null 2>&1; then
  for dir in "$HOME/.config/claude/profiles"/*/; do
    [[ -d "$dir" ]] || continue
    CLAUDE_CONFIG_DIR="${dir%/}" ensure claude "profile $(basename "$dir")"
  done
fi
