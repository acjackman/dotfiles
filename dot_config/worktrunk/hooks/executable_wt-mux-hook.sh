#!/usr/bin/env bash
# wt-mux-hook.sh - Pre-remove/merge hook: clear multiplexer panes out of a worktree
#
# Reads worktree_path and primary_worktree_path from stdin JSON (worktrunk hook
# context). Panes sitting in the worktree that run nothing but a shell are killed;
# panes running real work are reported and abort the operation. After cleanup the
# caller is landed on the primary worktree.
#
# BOTH tmux and herdr are scanned, whichever one invoked us — a busy herdr pane
# has to block a `wt remove` run from tmux (and vice versa), or the worktree gets
# deleted out from under live work. This is deliberately unlike `clank`'s "never
# cross the streams" dispatch: clank picks ONE substrate to *open* a surface on,
# whereas a safety check wants to see everything. Landing is the opposite — it is
# per-substrate, since you can't switch a tmux client to a herdr workspace, so
# each side lands only when it is the caller's own multiplexer.

set -euo pipefail

IDLE_SHELLS="^(zsh|bash|fish|sh)$"

# herdr's wire protocol churns pre-1.0, so pin it the way `clank` does (sharing
# its env var, so one bump moves both). An unrecognised protocol means we can't
# trust the pane JSON — warn loudly rather than silently skipping the check and
# deleting a worktree with live herdr work in it.
HERDR_PROTOCOLS="${CLANK_HERDR_PROTOCOLS:-14}"

warn() { printf 'wt-mux-hook: %s\n' "$*" >&2; }

ctx=$(cat)
worktree_path=$(printf '%s' "$ctx" | jq -r '.worktree_path')
primary_worktree_path=$(printf '%s' "$ctx" | jq -r '.primary_worktree_path')

wt_path_real="$(cd "$worktree_path" && pwd -P)"

# busy entries: substrate \t location \t cmd \t relpath \t focus-hint
busy_panes=()
tmux_idle=()
herdr_idle=()

in_worktree() {
  case "$1" in
    "$wt_path_real" | "$wt_path_real"/*) return 0 ;;
  esac
  return 1
}

rel_to_worktree() {
  local rel="${1#"$wt_path_real"}"
  rel="${rel#/}"
  [[ -z "$rel" ]] && rel="."
  printf '%s' "$rel"
}

# ---- tmux ------------------------------------------------------------------

tmux_active() { command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; }

scan_tmux() {
  tmux_active || return 0
  local pane_id pane_path pane_cmd session_name window_name pane_index pane_path_real loc
  while IFS=$'\t' read -r pane_id pane_path pane_cmd session_name window_name pane_index; do
    # Skip our own pane: it is running `wt`, which would read as busy.
    [[ "$pane_id" == "${TMUX_PANE:-}" ]] && continue
    pane_path_real="$(cd "$pane_path" 2>/dev/null && pwd -P)" || continue
    in_worktree "$pane_path_real" || continue
    if [[ "$pane_cmd" =~ $IDLE_SHELLS ]]; then
      tmux_idle+=("$pane_id")
    else
      loc="$session_name:$window_name.$pane_index"
      busy_panes+=("tmux	$loc	$pane_cmd	$(rel_to_worktree "$pane_path_real")	tmux switch-client -t '$loc'")
    fi
  done < <(tmux list-panes -a -F "#{pane_id}	#{pane_current_path}	#{pane_current_command}	#{session_name}	#{window_name}	#{pane_index}")
}

# ---- herdr -----------------------------------------------------------------

herdr_active() {
  command -v herdr >/dev/null 2>&1 || return 1
  local st proto
  st=$(herdr status server 2>/dev/null) || return 1
  grep -q '^status: running' <<<"$st" || return 1
  proto=$(sed -n 's/^protocol: *//p' <<<"$st" | head -1)
  case " $HERDR_PROTOCOLS " in
    *" ${proto:-none} "*) return 0 ;;
    *)
      warn "herdr protocol '${proto:-?}' not in supported set '$HERDR_PROTOCOLS' — NOT checking herdr panes (pin herdr, restart its server, or set CLANK_HERDR_PROTOCOLS)"
      return 1
      ;;
  esac
}

# $HERDR_PANE_ID is herdr's exact analogue of $TMUX_PANE: herdr exports it into
# each pane's environment, and it is unset everywhere else. Do NOT reach for
# `herdr pane current` here, tempting as it looks — it resolves by controlling
# TTY and silently falls back to the FOCUSED pane when the caller isn't a herdr
# pane at all. From tmux that would pin `self` to whatever pane Adam happens to be
# looking at, and if that pane were busy inside the worktree we'd skip it and
# delete the worktree out from under it — precisely the hole this hook exists to
# close. An unset var here is fail-safe by comparison: our own pane simply reads
# as busy (it is running `wt`) and aborts.
herdr_self_pane() { printf '%s' "${HERDR_PANE_ID:-}"; }

# The command a herdr pane is "at" — the analogue of tmux's pane_current_command.
# process-info reports the whole foreground process *group* (an agent's MCP
# children and all), so pick the group leader: the process the shell launched.
# The leader is occasionally missing from the list, so fall back to the last
# entry, which is where herdr orders it. Read argv0, never .name — claude reports
# its .name as the version string ("2.1.209").
herdr_pane_cmd() {
  herdr pane process-info --pane "$1" 2>/dev/null | jq -r '
    .result.process_info as $pi
    | ($pi.foreground_processes // []) as $fg
    | ([$fg[] | select(.pid == $pi.foreground_process_group_id) | .argv0] | first)
      // ([$fg[] | .argv0] | last)
      // ""'
}

scan_herdr() {
  herdr_active || return 0
  local self panes workspaces tabs pane_id cwd ws_id ws_label tab_label cmd loc
  # Empty unless herdr is the caller's own multiplexer, in which case this is the
  # pane running `wt` — which would otherwise read as busy and abort us.
  self=$(herdr_self_pane)
  panes=$(herdr pane list 2>/dev/null) || return 0
  workspaces=$(herdr workspace list 2>/dev/null) || workspaces='{}'
  tabs=$(herdr tab list 2>/dev/null) || tabs='{}'

  while IFS=$'\t' read -r pane_id cwd ws_id ws_label tab_label; do
    [[ -n "$pane_id" ]] || continue
    [[ "$pane_id" == "$self" ]] && continue
    [[ -n "$cwd" ]] || continue
    cwd="$(cd "$cwd" 2>/dev/null && pwd -P)" || continue
    in_worktree "$cwd" || continue
    cmd=$(herdr_pane_cmd "$pane_id")
    if [[ "$cmd" =~ $IDLE_SHELLS ]]; then
      herdr_idle+=("$pane_id")
    else
      # An unreadable command counts as busy: a spurious abort costs a message,
      # whereas killing a pane that was working is unrecoverable.
      loc="$ws_label/$tab_label"
      busy_panes+=("herdr	$loc	${cmd:-unknown}	$(rel_to_worktree "$cwd")	herdr workspace focus $ws_id")
    fi
  done < <(jq -r -n --argjson p "$panes" --argjson w "$workspaces" --argjson t "$tabs" '
    ($w.result.workspaces // []) as $wl
    | ($t.result.tabs // []) as $tl
    | ($p.result.panes // [])[]
    | . as $pane
    | (([$wl[] | select(.workspace_id == $pane.workspace_id) | .label] | first) // $pane.workspace_id) as $ws
    | (([$tl[] | select(.tab_id == $pane.tab_id) | .label] | first) // $pane.tab_id) as $tab
    | [$pane.pane_id, ($pane.cwd // ""), $pane.workspace_id, $ws, $tab] | @tsv')
}

# ---- landing ---------------------------------------------------------------

land_tmux() {
  local landing_session
  landing_session="$(tmux-session-name "$primary_worktree_path")"
  if ! tmux has-session -t "=$landing_session" 2>/dev/null; then
    tmux new-session -d -s "$landing_session" -c "$primary_worktree_path"
  fi
  tmux switch-client -t "=$landing_session"
}

# The herdr mirror of land_tmux, so emptying the worktree's panes doesn't dump
# the user wherever herdr happens to compact to. Located by pane cwd rather than
# by label: herdr labels are free-form and one workspace can hold panes from
# several worktrees, so cwd is the only reliable locator.
land_herdr() {
  local primary_real ws label
  primary_real="$(cd "$primary_worktree_path" 2>/dev/null && pwd -P)" || return 0
  ws=$(herdr pane list 2>/dev/null | jq -r --arg p "$primary_real" '
    [.result.panes[]? | select(.cwd == $p or ((.cwd // "") | startswith($p + "/"))) | .workspace_id] | first // ""')
  if [[ -z "$ws" ]]; then
    label="$(tmux-session-name --repo "$primary_worktree_path" 2>/dev/null || basename "$primary_real")"
    ws=$(herdr workspace create --cwd "$primary_worktree_path" --label "$label" --no-focus 2>/dev/null |
      jq -r '.result.workspace.workspace_id // ""')
  fi
  [[ -n "$ws" ]] || return 0
  herdr workspace focus "$ws" >/dev/null 2>&1 || true
}

# ---- run -------------------------------------------------------------------

scan_tmux
scan_herdr

if [[ ${#busy_panes[@]} -gt 0 ]]; then
  echo "error: busy panes in worktree directory:" >&2
  for entry in "${busy_panes[@]}"; do
    IFS=$'\t' read -r substrate loc cmd path hint <<<"$entry"
    printf '  %-5s [%s] %s (%s)\n' "$substrate" "$loc" "$cmd" "$path" >&2
    echo "    → $hint" >&2
  done
  echo "Close these applications before proceeding." >&2
  exit 1
fi

if [[ ${#tmux_idle[@]} -gt 0 ]]; then
  # Land before killing so the client isn't holding a session we're about to
  # empty — only meaningful with an attached client, i.e. when tmux is our host.
  [[ -n "${TMUX:-}" ]] && land_tmux
  for pane_id in "${tmux_idle[@]}"; do
    tmux kill-pane -t "$pane_id" 2>/dev/null || true
  done
fi

if [[ ${#herdr_idle[@]} -gt 0 ]]; then
  # Same rule as land_tmux: only land when herdr is the caller's own host,
  # otherwise we'd yank the focus of whoever is using herdr right now.
  [[ -n "$(herdr_self_pane)" ]] && land_herdr
  for pane_id in "${herdr_idle[@]}"; do
    herdr pane close "$pane_id" >/dev/null 2>&1 || true
  done
fi

exit 0
