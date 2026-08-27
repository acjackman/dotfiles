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
# Scripts are excluded throughout (-x scripts). chezmoi runs run_ scripts on apply
# by design: an R entry can never be file drift, and plain run_ scripts are pending
# permanently, so they carry no information. chezmoi diff also renders scripts as
# "new file mode 100755" against /dev/null, which reads exactly like a genuinely
# new managed file and has caused agents to try to execute the target path.
# See .docs/chezmoi.md for how run_ scripts work.
echo "=== STATUS ==="
status_output="$(chezmoi status -x scripts "${source_flag[@]}" "${target_paths[@]}" 2>&1)" || true
# Scripts that would actually do something: run_onchange_/run_once_ that are
# pending. -x always drops the plain run_ scripts, which are always pending.
pending_scripts="$(chezmoi status -i scripts -x always "${source_flag[@]}" "${target_paths[@]}" 2>&1)" || true

if [[ -z "$status_output" && -z "$pending_scripts" ]]; then
  echo "(no pending changes)"
  echo ""
  echo "=== DONE ==="
  echo "Nothing to apply."
  exit 0
fi

if [[ -n "$status_output" ]]; then
  echo "$status_output"
else
  # Only a script is pending — e.g. you edited a run_onchange_ script body, or a
  # file it hashes. Still worth applying; there is just nothing to diff.
  echo "(no file changes; chezmoi will run its scripts as usual)"
fi
echo ""

# --- Diff ---
echo "=== DIFF ==="
# -r because chezmoi diff (unlike status) does NOT recurse into a directory
# argument by default, so a directory-scoped preview silently showed nothing.
chezmoi diff -r -x scripts "${source_flag[@]}" "${target_paths[@]}" 2>&1 || true
echo ""

# --- Worktree caution ---
if [[ "$in_worktree" == true ]]; then
  echo "=== WORKTREE CAUTION ==="
  echo "run_onchange_ scripts record their state globally"
  echo "(~/.config/chezmoi/chezmoistate.boltdb), not per-worktree. Applying broadly"
  echo "from a worktree can leave that state inconsistent with the default source."
  echo "Prefer targeted applies. See .docs/chezmoi-worktrees.md."
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
