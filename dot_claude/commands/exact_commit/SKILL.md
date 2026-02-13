---
allowed-tools:
  - Bash(bash ~/.claude/commands/commit/git-commit-info.sh:*)
  - Bash(git status:*)
  - Bash(git add:*)
  - Bash(git commit:*)
---

# Commit Changes

Create a git commit with a well-structured commit message.

## Instructions

1. Run `git-commit-info.sh` to gather context, status, diff, recent commits, and warnings:

   ```bash
   bash ~/.claude/commands/commit/git-commit-info.sh
   ```

2. Analyze all changes for the conversation and draft a commit message:
   - Summarize the nature of changes (new feature, enhancement, bug fix, refactoring, etc.)
   - Focus on the "why" rather than the "what"
   - Keep it concise (1-2 sentences)
   - Match the repository's existing commit message style

3. Stage and commit:
   - Avoid using `git -C` unless required to operate on a different repository. USe plain git commands for the current worktree or repository.
   - Add relevant files individually (avoid `git add -A` or `git add .`) There may be other files in the repo that should not be added.
   - Never commit files flagged in the WARNINGS section (secrets, credentials, etc.)
   - Combine staging and committing when possible, and always include a Co-Authored-By trailer for the agent:

     ```bash
     git add file1 file2 && git commit -m "$(cat <<'EOF'
     Commit message here.

     Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
     EOF
     )"
     ```

4. Run `git status` after committing to verify success.

## Important

- Follow the guidance printed by `git-commit-info.sh` — especially the GIT CONTEXT section which confirms you are inside the repo. Never use `git -C` for the current directory.
- Never amend commits unless explicitly requested
- Never force push or modify git config
- Never skip pre-commit hooks
- If a pre-commit hook fails, fix the issue and create a NEW commit
- Do not push unless explicitly asked
