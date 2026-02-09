---
allowed-tools:
  - Bash(bash ~/.config/claude/commands/commit/git-commit-info.sh:Gather git branch, status, diff, and recent commits)
  - Bash(git status:*)
  - Bash(git add:*)
  - Bash(git commit:*)
---

# Commit Changes

Create a git commit with a well-structured commit message.

## Instructions

1. Run the `git-commit-info.sh` script from this skill directory to gather branch, status, diff, recent commits, and warnings in one call:
   ```bash
   bash ~/.config/claude/commands/commit/git-commit-info.sh
   ```

2. Analyze all changes and draft a commit message:
   - Summarize the nature of changes (new feature, enhancement, bug fix, refactoring, etc.)
   - Focus on the "why" rather than the "what"
   - Keep it concise (1-2 sentences)
   - Match the repository's existing commit message style

3. Stage and commit:
   - Add relevant files individually (avoid `git add -A` or `git add .`)
   - Never commit files flagged in the WARNINGS section (secrets, credentials, etc.)
   - Combine staging and committing when possible:
     ```bash
     git add file1 file2 && git commit -m "$(cat <<'EOF'
     Commit message here.

     Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
     EOF
     )"
     ```

4. Run `git status` after committing to verify success.

## Important

- Only use `git -C` if not already in the repository or worktree root.
- Never amend commits unless explicitly requested
- Never force push or modify git config
- Never skip pre-commit hooks
- If a pre-commit hook fails, fix the issue and create a NEW commit
- Do not push unless explicitly asked
