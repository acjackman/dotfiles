---
name: apply
description: Apply chezmoi dotfile changes to deploy them to target locations
allowed-tools:
  - Bash(bash "$(git rev-parse --show-toplevel)/.claude/skills/apply/chezmoi-apply-info.sh":*)
  - Bash(chezmoi diff:*)
  - Bash(chezmoi apply:*)
  - Bash(chezmoi status:*)
  - Bash(chezmoi source-path:*)
  - Bash(git rev-parse:*)
---

# Apply Chezmoi Changes

Apply chezmoi dotfile changes from the source repository to their target locations. This skill is worktree-aware and handles both the default source directory and git worktrees.

## Instructions

1. Run the apply info script to preview changes:
   ```sh
   bash "$(git rev-parse --show-toplevel)/.claude/skills/apply/chezmoi-apply-info.sh" [target-path ...]
   ```
   Pass target paths to scope the preview to specific files.

2. Review the structured output:
   - **STATUS**: Pending changes (A=add, M=modify, R=run script)
   - **DIFF**: Actual file changes
   - **WARNINGS**: Scripts that will execute, worktree-specific cautions
   - **APPLY COMMAND**: The exact command to run

3. Apply using the command from the `APPLY COMMAND` section.

4. Verify with the info script again (or `chezmoi status` with `--source` if in a worktree) to confirm changes were applied.

## Important

- **Never use `chezmoi apply --force`** — it silently overwrites locally-diverged files
- If chezmoi errors due to a conflict, **stop and notify the user** — they may have local changes to merge
- **From worktrees: always use targeted applies** (specific target paths). Broad applies pollute global persistent state and may re-trigger `run_onchange_` scripts unexpectedly. See `.docs/chezmoi-worktrees.md`
- **Unexpected diffs** may mean another agent applied from a different worktree — alert the user
- Files with status "R" are scripts that will be **executed**, not created
- Never modify deployed files directly — always edit the chezmoi source
