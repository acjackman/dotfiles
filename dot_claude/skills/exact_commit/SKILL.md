---
name: commit
description: Commit staged and unstaged changes with a well-structured message. Use when the user says "commit", "commit this", "save my changes", or asks to create a git commit.
allowed-tools:
  - Agent
  - "Bash(bash */commit/scripts/git-commit-info.sh)"
---

# Commit Changes

Delegate the commit to a sub-agent so diffs and analysis stay out of the main context.

## Instructions

Spawn a **single** Agent call with the following settings:

- **description**: `"Git commit"`
- **model**: `"haiku"`
- **prompt**: Include the full commit instructions below, replacing `$CWD` with the current working directory path and `$SKILL_DIR` with the base directory shown at the top of this skill.

```
You are a git commit agent. Work in the directory: $CWD

1. Run the commit-info script to gather context, status, diff, recent commits, and warnings:

   bash $SKILL_DIR/scripts/git-commit-info.sh

2. Analyze all changes and draft a commit message:
   - Summarize the nature of changes (new feature, enhancement, bug fix, refactoring, etc.)
   - Focus on the "why" rather than the "what"
   - Keep it concise (1-2 sentences)
   - Match the repository's existing commit message style

3. Stage and commit:
   - Use plain git commands (no git -C for the current repo).
   - Add relevant files individually (avoid git add -A or git add .). There may be other files in the repo that should not be added.
   - Never commit files flagged in the WARNINGS section (secrets, credentials, etc.)
   - Combine staging and committing when possible, and always append the trailers from the === TRAILERS === section of the script output after a blank line:

     git add file1 file2 && git commit -m "$(cat <<'EOF'
     Commit message here.

     Co-Authored-By: Claude <noreply@anthropic.com>
     Harness: claude-code
     Model: Claude
     EOF
     )"

     The example above shows Claude Code defaults — use the actual trailer lines printed by the script.

4. Run git status after committing to verify success.

Rules:
- Follow the guidance printed by git-commit-info.sh — especially the GIT CONTEXT section.
- Never amend commits unless explicitly requested.
- Never force push or modify git config.
- Never skip pre-commit hooks.
- If a pre-commit hook fails, fix the issue and create a NEW commit.
- Do not push unless explicitly asked.

Return a short summary: the commit hash (short), the commit message, and the list of files committed.
```

After the agent completes, relay its summary to the user.
