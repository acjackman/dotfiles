# wt-tmux-cleanup.sh - Shared tmux cleanup logic for wt wrapper scripts
#
# Sourced by wtm/wtrm. Expects to be called as:
#   source ".../wt-tmux-cleanup.sh" <action> [args...]
#
# where <action> is the wt subcommand (e.g. "remove", "merge").
# Parses remaining args, resolves worktree paths, cleans up tmux panes,
# then execs `wt <action> --foreground` with the parsed args.

set -euo pipefail

wt_action="$1"; shift

IDLE_SHELLS="^(zsh|bash|fish|sh)$"
dry_run=false

# --- Parse args: separate wt flags from branch names ---
# Flags that consume a following value
VALUE_FLAGS="-C|--config"

wt_args=()
branches=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=true
      shift
      ;;
    -C|--config)
      wt_args+=("$1" "$2")
      shift 2
      ;;
    -*)
      wt_args+=("$1")
      shift
      ;;
    *)
      branches+=("$1")
      shift
      ;;
  esac
done

# --- Resolve worktree paths ---
resolve_worktree_path() {
  local branch="$1"
  git worktree list --porcelain | awk -v branch="$branch" '
    /^worktree / { wt = substr($0, 10) }
    /^branch / {
      b = substr($0, 8)
      if (b == "refs/heads/" branch) print wt
    }
  '
}

main_wt="$(git worktree list --porcelain | head -1 | sed 's/^worktree //')"
main_wt_real="$(cd "$main_wt" && pwd -P)"

worktree_paths=()
if [[ ${#branches[@]} -eq 0 ]]; then
  wt_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "error: not in a git worktree" >&2
    exit 1
  }
  wt_root_real="$(cd "$wt_root" && pwd -P)"

  if [[ "$wt_root_real" == "$main_wt_real" ]]; then
    echo "error: cannot $wt_action the main worktree" >&2
    exit 1
  fi

  worktree_paths=("$wt_root_real")
else
  for branch in "${branches[@]}"; do
    path=$(resolve_worktree_path "$branch")
    if [[ -z "$path" ]]; then
      echo "error: no worktree found for branch '$branch'" >&2
      exit 1
    fi
    path_real="$(cd "$path" && pwd -P)"

    if [[ "$path_real" == "$main_wt_real" ]]; then
      echo "error: cannot $wt_action the main worktree" >&2
      exit 1
    fi

    worktree_paths+=("$path_real")
  done
fi

# --- Tmux cleanup ---
if [[ -n "${TMUX:-}" ]]; then
  busy_panes=()
  idle_panes=()

  for wt_path in "${worktree_paths[@]}"; do
    while IFS=$'\t' read -r pane_id pane_path pane_cmd session_name; do
      # Resolve symlinks in pane path for accurate comparison
      pane_path_real="$(cd "$pane_path" 2>/dev/null && pwd -P)" || continue

      case "$pane_path_real" in
        "$wt_path"|"$wt_path"/*)
          if [[ "$pane_cmd" =~ $IDLE_SHELLS ]]; then
            idle_panes+=("$pane_id")
          else
            busy_panes+=("$pane_id	$session_name	$pane_cmd	$pane_path_real")
          fi
          ;;
      esac
    done < <(tmux list-panes -a -F "#{pane_id}	#{pane_current_path}	#{pane_current_command}	#{session_name}")
  done

  if $dry_run; then
    echo "--- dry run: tmux pane scan ---"
    echo "worktree paths: ${worktree_paths[*]}"
    echo "idle panes to kill (${#idle_panes[@]}):"
    for pane_id in "${idle_panes[@]+"${idle_panes[@]}"}"; do
      pane_info=$(tmux display-message -t "$pane_id" -p "#{session_name}:#{window_name}.#{pane_index} #{pane_current_path} (#{pane_current_command})" 2>/dev/null) || pane_info="$pane_id (info unavailable)"
      if [[ "$pane_id" == "$TMUX_PANE" ]]; then
        echo "  $pane_info  [SKIP: own pane]"
      else
        echo "  $pane_info  [WOULD KILL]"
      fi
    done
    echo "busy panes (${#busy_panes[@]}):"
    for entry in "${busy_panes[@]+"${busy_panes[@]}"}"; do
      IFS=$'\t' read -r id sess cmd path <<< "$entry"
      echo "  [$sess] $cmd ($path)  [WOULD BLOCK]"
    done
    echo "landing session: $(tmux-session-name "$main_wt")"
    echo "---"
    echo "would exec: wt $wt_action --foreground ${wt_args[*]+${wt_args[*]}} ${branches[*]+${branches[*]}}"
    exit 0
  fi

  if [[ ${#busy_panes[@]} -gt 0 ]]; then
    echo "error: busy panes in worktree directory:" >&2
    for entry in "${busy_panes[@]}"; do
      IFS=$'\t' read -r id sess cmd path <<< "$entry"
      echo "  [$sess] $cmd ($path)" >&2
    done
    echo "Close these applications before ${wt_action%e}ing the worktree." >&2
    exit 1
  fi

  if [[ ${#idle_panes[@]} -gt 0 ]]; then
    landing_session="$(tmux-session-name "$main_wt")"

    # Ensure landing session exists
    if ! tmux has-session -t "=$landing_session" 2>/dev/null; then
      tmux new-session -d -s "$landing_session" -c "$main_wt"
    fi

    # Switch to landing session first (before killing panes that may include current)
    tmux switch-client -t "=$landing_session"

    # Kill idle panes, but skip our own pane (it needs to finish running wt)
    for pane_id in "${idle_panes[@]}"; do
      [[ "$pane_id" == "$TMUX_PANE" ]] && continue
      tmux kill-pane -t "$pane_id" 2>/dev/null || true
    done
  fi
fi

if $dry_run; then
  echo "--- dry run (no tmux) ---"
  echo "worktree paths: ${worktree_paths[*]}"
  echo "would exec: wt $wt_action --foreground ${wt_args[*]+${wt_args[*]}} ${branches[*]+${branches[*]}}"
  exit 0
fi

# --- Execute wt action ---
exec wt "$wt_action" --foreground "${wt_args[@]+"${wt_args[@]}"}" "${branches[@]+"${branches[@]}"}"
