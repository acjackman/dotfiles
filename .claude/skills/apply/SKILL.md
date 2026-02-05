---
name: apply
description: Apply chezmoi dotfile changes to deploy them to target locations
allowed-tools:
  - Bash(chezmoi diff:*)
  - Bash(chezmoi apply:*)
  - Bash(chezmoi status:*)
  - Bash(chezmoi source-path:*)
---

# Apply Chezmoi Changes

Apply chezmoi dotfile changes from the source repository to their target locations.

## Instructions

1. First, preview the changes that will be applied:
   - Run `chezmoi diff` to show what will change
   - Review the diff output to understand what operations will occur

2. Interpret the diff correctly:
   - Check `chezmoi status` to see file operation codes (A=add, M=modify, R=run script)
   - Files with status "R" are scripts that will be EXECUTED, not created
   - Scripts with `run_once_`, `run_onchange_`, or `run_` prefixes execute but don't create files
   - Regular files (with `dot_`, `private_`, `executable_` prefixes) will be created/modified
   - Report scripts as "will execute" and files as "will be created/modified"

3. Apply the changes:
   - Run `chezmoi apply` to deploy all pending changes
   - This updates the target files and executes any run scripts

4. Verify and report:
   - Confirm the command completed successfully
   - Report any errors or conflicts to the user
   - Summarize what was deployed vs what was executed

## Important

- Always show the diff before applying when making significant changes
- Never modify deployed files directly (e.g., `~/.zshrc`) - always edit the chezmoi source
- If conflicts occur, check for manual edits in target locations
- Use `chezmoi apply --force` only when explicitly requested

## Allowed Operations

This skill grants permission to run:
- `chezmoi diff` - Preview changes
- `chezmoi apply` - Apply changes to target locations
