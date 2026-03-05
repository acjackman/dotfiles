#!/usr/bin/env bash
# chezmoi-apply-info.sh — Worktree-aware chezmoi apply helper
# Outputs structured sections for the apply skill to consume.
# Usage: chezmoi-apply-info.sh [target-path ...]
set -eo pipefail

# --- Resolve paths ---
git_toplevel="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "ERROR: Not inside a git repository." >&2
  exit 1
}

chezmoi_default_source="$(chezmoi source-path)"
target_paths=("$@")

# --- Worktree detection ---
source_flag=()
in_worktree=false

if [[ "$git_toplevel" != "$chezmoi_default_source" ]]; then
  in_worktree=true
  source_flag=(--source "$git_toplevel")
  echo "=== WORKTREE DETECTED ==="
  echo "Worktree path:       $git_toplevel"
  echo "Default source path: $chezmoi_default_source"
  echo ""
  echo "All chezmoi commands MUST include: --source $git_toplevel"
else
  echo "=== DEFAULT SOURCE ==="
  echo "Source path: $chezmoi_default_source"
fi
echo ""

# --- Status ---
echo "=== STATUS ==="
status_output="$(chezmoi status "${source_flag[@]}" "${target_paths[@]}" 2>&1)" || true
if [[ -z "$status_output" ]]; then
  echo "(no pending changes)"
  echo ""
  echo "=== DONE ==="
  echo "Nothing to apply."
  exit 0
fi
echo "$status_output"
echo ""

# --- Diff ---
echo "=== DIFF ==="
chezmoi diff "${source_flag[@]}" "${target_paths[@]}" 2>&1 || true
echo ""

# --- Warnings ---
script_lines="$(echo "$status_output" | grep '^.R ' || true)"
if [[ -n "$script_lines" ]]; then
  echo "=== WARNINGS ==="
  echo "The following scripts will EXECUTE (not create files):"
  echo "$script_lines"
  if [[ "$in_worktree" == true ]]; then
    echo ""
    echo "WARNING: run_onchange_ scripts affect GLOBAL persistent state"
    echo "(~/.config/chezmoi/chezmoistate.boltdb). Running them from a worktree"
    echo "may cause them to re-trigger when applying from the default source later."
    echo "See .docs/chezmoi-worktrees.md for details."
  fi
  echo ""
fi

# --- Apply command ---
echo "=== APPLY COMMAND ==="
cmd="chezmoi apply"
if [[ ${#source_flag[@]} -gt 0 ]]; then
  cmd+=" --source $git_toplevel"
fi

if [[ ${#target_paths[@]} -gt 0 ]]; then
  for tp in "${target_paths[@]}"; do
    cmd+=" $tp"
  done
  echo "$cmd"
elif [[ "$in_worktree" == true ]]; then
  echo "WARNING: Broad apply from a worktree is discouraged."
  echo "It deploys ALL worktree files and pollutes global persistent state."
  echo "Prefer targeted applies for specific files you changed:"
  echo ""
  echo "  chezmoi apply --source $git_toplevel <target-path> [<target-path> ...]"
  echo ""
  echo "If you must apply everything:"
  echo "  $cmd"
else
  echo "$cmd"
fi
echo ""
echo "=== DONE ==="
