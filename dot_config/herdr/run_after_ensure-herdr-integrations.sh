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
#             Repeated for each ~/.config/claude/profiles/* (CLAUDE_CONFIG_DIR).
#   codex   — herdr-agent-state.sh + hooks.json in $CODEX_HOME (unmanaged), and
#             `[features] hooks = true` in config.toml, which is GENERATED — so
#             that flag lives in dot_config/codex/exact_config.d/10-features.toml.
set -euo pipefail

command -v herdr >/dev/null 2>&1 || exit 0

# Agents to integrate, when installed. Each maps to its CLI name on PATH.
agents=(claude codex pi omp)

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

for agent in "${agents[@]}"; do
  command -v "$agent" >/dev/null 2>&1 || continue
  # omp's installer refuses until omp has created its own extensions dir (first
  # run), so wait for it rather than warning on every apply until then.
  [[ "$agent" == omp && ! -d "$HOME/.omp/agent/extensions" ]] && continue
  ensure "$agent" ""
done

# Extra Claude config dirs (profiles) each carry their own hooks + settings.json.
if command -v claude >/dev/null 2>&1; then
  for dir in "$HOME/.config/claude/profiles"/*/; do
    [[ -d "$dir" ]] || continue
    CLAUDE_CONFIG_DIR="${dir%/}" ensure claude "profile $(basename "$dir")"
  done
fi
