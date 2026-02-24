#!/usr/bin/env bash

# Gather git commit info in a single call for efficient LLM-assisted commits.
# Outputs structured sections: agent info, branch, status, diff stat, diff,
# recent commits, warnings, and pre-built trailers.

set -euo pipefail

MAX_DIFF_LINES="${GIT_COMMIT_INFO_MAX_LINES:-200}"

# --- Agent / harness detection ---
detect_harness() {
    if [[ -n "${CLAUDECODE:-}" ]]; then
        echo "claude-code"
    elif [[ -n "${GEMINI_CLI:-}" ]]; then
        echo "gemini-cli"
    elif [[ -n "${CURSOR_AGENT:-}" ]]; then
        echo "cursor"
    elif [[ -n "${OPENCODE:-}" ]]; then
        echo "opencode"
    else
        echo "unknown"
    fi
}

harness_defaults() {
    local harness="$1"
    case "$harness" in
        claude-code) default_model="Claude";     email_domain="anthropic.com" ;;
        gemini-cli)  default_model="Gemini";     email_domain="google.com" ;;
        cursor)      default_model="Cursor AI";  email_domain="cursor.com" ;;
        opencode)    default_model="OpenCode AI"; email_domain="opencode.dev" ;;
        *)           default_model="LLM Agent"; email_domain="" ;;
    esac
}

harness=$(detect_harness)
harness_defaults "$harness"
model="${GIT_COMMIT_AGENT_MODEL:-$default_model}"

# Ensure we're in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: not a git repository"
    exit 1
fi

# === GIT CONTEXT ===
# Show the model it's inside a valid worktree — no need for git -C.
echo "=== GIT CONTEXT ==="
echo "cwd:       $(pwd)"
echo "toplevel:  $(git rev-parse --show-toplevel)"
if git rev-parse --git-common-dir >/dev/null 2>&1; then
    common_dir=$(git rev-parse --git-common-dir)
    toplevel_git=$(git rev-parse --git-dir)
    if [[ "$common_dir" != "$toplevel_git" ]]; then
        echo "worktree:  yes (linked to $(cd "$common_dir/.." && pwd))"
    else
        echo "worktree:  no (main checkout)"
    fi
fi
echo "All plain git commands operate on this repo. Do not use git -C."
echo ""

# === AGENT INFO ===
echo "=== AGENT INFO ==="
echo "harness: $harness"
echo "model:   $model"
echo ""

# Check for changes
status=$(git status --short)
if [[ -z "$status" ]]; then
    echo "Working tree is clean — nothing to commit."
    exit 0
fi

# === BRANCH ===
echo "=== BRANCH ==="
git rev-parse --abbrev-ref HEAD
echo ""

# === STATUS ===
echo "=== STATUS ==="
echo "$status"
echo ""

# === DIFF STAT ===
echo "=== DIFF STAT ==="
staged_stat=$(git diff --cached --stat)
[[ -n "$staged_stat" ]] && echo "Staged:" && echo "$staged_stat"
unstaged_stat=$(git diff --stat)
[[ -n "$unstaged_stat" ]] && echo "Unstaged:" && echo "$unstaged_stat"
echo ""

# === DIFF ===
echo "=== DIFF ==="
diff_output=""
staged_diff=$(git diff --cached)
unstaged_diff=$(git diff)

if [[ -n "$staged_diff" && -n "$unstaged_diff" ]]; then
    diff_output=$(printf "# Staged changes\n%s\n\n# Unstaged changes\n%s" "$staged_diff" "$unstaged_diff")
elif [[ -n "$staged_diff" ]]; then
    diff_output="$staged_diff"
elif [[ -n "$unstaged_diff" ]]; then
    diff_output="$unstaged_diff"
fi

if [[ -n "$diff_output" ]]; then
    total_lines=$(echo "$diff_output" | wc -l)
    if [[ $total_lines -gt $MAX_DIFF_LINES ]]; then
        echo "$diff_output" | head -n "$MAX_DIFF_LINES"
        omitted=$((total_lines - MAX_DIFF_LINES))
        echo "[... $omitted lines omitted ...]"
    else
        echo "$diff_output"
    fi
else
    echo "(no diff — changes may be untracked files only)"
fi
echo ""

# === RECENT COMMITS ===
echo "=== RECENT COMMITS ==="
git log -5 --oneline 2>/dev/null || echo "(no commits yet)"
echo ""

# === WARNINGS ===
secret_patterns='\.env$|\.pem$|\.key$|credentials|\.secret|\.p12$|\.pfx$|\.jks$|id_rsa|id_ed25519'
warnings=""
while IFS= read -r line; do
    file="${line:3}"
    if echo "$file" | grep -qEi "$secret_patterns"; then
        warnings="${warnings}Potential secret file: ${file}\n"
    fi
done <<< "$status"

if [[ -n "$warnings" ]]; then
    echo "=== WARNINGS ==="
    printf "%b" "$warnings"
    echo ""
fi

# === TRAILERS ===
echo "=== TRAILERS ==="
if [[ -n "$email_domain" ]]; then
    echo "Co-Authored-By: $model <noreply@$email_domain>"
else
    echo "Co-Authored-By: $model"
fi
echo "Harness: $harness"
echo "Model: $model"
