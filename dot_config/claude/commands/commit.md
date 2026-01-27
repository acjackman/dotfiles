---
allowed-tools:
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git add:*)
  - Bash(git commit:*)
---

# Commit Changes

Create a git commit with a well-structured commit message.

## Instructions

1. First, gather information about the current state by running these commands in parallel:
   - `git status` to see all untracked and modified files
   - `git diff` to see staged and unstaged changes
   - `git log -5 --oneline` to see recent commit message style

2. Analyze all changes and draft a commit message:
   - Summarize the nature of changes (new feature, enhancement, bug fix, refactoring, etc.)
   - Focus on the "why" rather than the "what"
   - Keep it concise (1-2 sentences)
   - Match the repository's existing commit message style

3. Stage and commit:
   - Add relevant files individually (avoid `git add -A` or `git add .`)
   - Never commit files that may contain secrets (.env, credentials, etc.)
   - Use a HEREDOC for the commit message:
     ```bash
     git commit -m "$(cat <<'EOF'
     Commit message here.

     Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
     EOF
     )"
     ```

4. Run `git status` after committing to verify success.

## Important

- Never amend commits unless explicitly requested
- Never force push or modify git config
- Never skip pre-commit hooks
- If a pre-commit hook fails, fix the issue and create a NEW commit
- Do not push unless explicitly asked

## Allowed Operations

This skill grants permission to run:
- `git add <files>`
- `git commit`
