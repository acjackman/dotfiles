#!/usr/bin/env bash
set -euo pipefail
# Pre-seed Claude Code's per-directory state for the current worktree so a fresh
# `,agnt` doesn't open on approval prompts:
#
#   1. Mark the directory trusted in ~/.claude.json (skips the trust dialog).
#   2. If the repo ships a checked-in .mcp.json, write enableAllProjectMcpServers
#      into .claude/settings.local.json (skips the "N new MCP servers found"
#      picker). settings.local.json is globally gitignored, so this is a local
#      opt-in that never reaches the shared repo.
#
# Designed to run as a worktrunk post-switch hook where $PWD is the worktree.

path="$PWD"

claude_json="$HOME/.claude.json"
if [[ -f "$claude_json" ]] &&
    ! jq -e --arg p "$path" '.projects[$p].hasTrustDialogAccepted == true' "$claude_json" >/dev/null 2>&1; then
    tmp="${claude_json}.tmp.$$"
    jq --arg p "$path" '.projects[$p] = (.projects[$p] // {}) + {"hasTrustDialogAccepted": true}' "$claude_json" >"$tmp" &&
        mv "$tmp" "$claude_json"
fi

# Only auto-enable MCP servers the repo itself declares. No .mcp.json means
# there's nothing to approve.
[[ -f "$path/.mcp.json" ]] || exit 0

local_settings="$path/.claude/settings.local.json"

if [[ -f "$local_settings" ]]; then
    # Never override an answer already on file. That includes a deliberate
    # opt-out (disabledMcpjsonServers) or a hand-picked subset
    # (enabledMcpjsonServers) — re-enabling those behind the user's back is
    # worse than an extra prompt.
    jq -e 'has("enableAllProjectMcpServers") or has("enabledMcpjsonServers") or has("disabledMcpjsonServers")' \
        "$local_settings" >/dev/null 2>&1 && exit 0
    tmp="${local_settings}.tmp.$$"
    jq '. + {"enableAllProjectMcpServers": true}' "$local_settings" >"$tmp" && mv "$tmp" "$local_settings"
else
    mkdir -p "$path/.claude"
    printf '{\n  "enableAllProjectMcpServers": true\n}\n' >"$local_settings"
fi
