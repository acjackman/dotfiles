#!/usr/bin/env bash
# Test: tmux-session-name should handle bare repo .bare directories correctly
#
# Reproduces AJ-41: wtrm fails with "duplicate session: _bare"
# Root cause: tmux-session-name falls through to basename fallback for .bare dirs
# because `git rev-parse --show-toplevel` fails in bare repos.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMUX_SESSION_NAME="$REPO_ROOT/dot_local/bin/executable_tmux-session-name"

PASS=0
FAIL=0
report() {
  if [[ "$1" == "PASS" ]]; then
    echo "  PASS: $2"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $2"
    FAIL=$((FAIL + 1))
  fi
}

# Create a temporary bare repo structure
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

REPO_NAME="my-project"
REPO_DIR="$TEST_DIR/$REPO_NAME"
mkdir -p "$REPO_DIR"

# Initialize as a bare repo with .bare structure (same as worktrunk setup)
git init --bare "$REPO_DIR/.bare" >/dev/null 2>&1

# Create a default branch with a commit so worktree operations work
cd "$REPO_DIR/.bare"
tree=$(git hash-object -t tree /dev/null 2>/dev/null || echo "4b825dc642cb6eb9a060e54bf899d15363d7c3ee")
commit=$(echo "init" | git commit-tree "$tree" 2>/dev/null) || true
if [[ -n "${commit:-}" ]]; then
  git update-ref refs/heads/main "$commit" 2>/dev/null || true
  git symbolic-ref HEAD refs/heads/main 2>/dev/null || true
fi

run_tmux_session_name() {
  local dir="$1"
  bash "$TMUX_SESSION_NAME" "$dir" 2>/dev/null || true
}

echo "=== AJ-41: tmux-session-name bare repo handling ==="

# Test 1: Must not return ".bare" for bare repo paths
# This is the core bug — returning ".bare" causes tmux to create "_bare" sessions
# and the has-session exact match check to fail
result=$(run_tmux_session_name "$REPO_DIR/.bare")

if [[ "$result" == ".bare" ]]; then
  report FAIL "returns '.bare' for bare repo path (causes duplicate session bug)"
  echo ""
  echo "    Root cause of AJ-41:"
  echo "      1. tmux-session-name returns '.bare' for bare repo main worktree paths"
  echo "      2. tmux converts '.' to '_', creating session '_bare'"
  echo "      3. has-session -t '=.bare' doesn't match existing '_bare' session"
  echo "      4. new-session -s '.bare' fails with 'duplicate session: _bare'"
else
  report PASS "does not return '.bare' for bare repo path"
fi

# Test 2: Result should start with the repo name, not with a dot
if [[ "$result" == "$REPO_NAME" || "$result" == "$REPO_NAME/"* ]]; then
  report PASS "returns repo-based name ('$result') for bare repo path"
else
  report FAIL "expected name starting with '$REPO_NAME', got '$result'"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
