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
   - **STATUS**: File changes (`A`=add, `M`=modify, `D`=delete)
   - **DIFF**: The actual content changes — review these
   - **WORKTREE CAUTION**: Only when applying from a worktree
   - **APPLY COMMAND**: The exact command to run

3. Apply using the command from the `APPLY COMMAND` section.

4. Verify with `chezmoi status -x scripts` (add `--source` if in a worktree). Empty output means everything deployed.

## Important

- **Never reach for `chezmoi apply --force` to get past a problem** — it silently overwrites locally-diverged files
- On a conflict, or on `could not open a new TTY: /dev/tty`: chezmoi wants an interactive answer it cannot get. Do **not** force. Diff the divergence (`chezmoi diff <path>`), copy the destination file aside if it holds real local edits, and show the user both sides. `--force` is theirs to authorize, per path, never a default
- **From worktrees: always use targeted applies** (specific target paths). Broad applies pollute global persistent state. See `.docs/chezmoi-worktrees.md`
- **Unexpected diffs** may mean another agent applied from a different worktree — alert the user
- **Target paths must be absolute.** A relative path resolves against the source dir and chezmoi reports "not managed".
- **Scope to the directory, not the file**, when the directory holds a `run_onchange_` script — a path-scoped apply skips scripts outside that path (`chezmoi apply ~/.config/herdr`, not `.../herdr/config.toml`).
- Never modify deployed files directly — always edit the chezmoi source
- **Some configs have special apply instructions** (especially for worktrees). Check the directory's `CLAUDE.md` before applying. Known configs with `data/`-sourced `run_onchange_` scripts that pollute state from worktrees:
  - `data/karabiner/` — run `goku` directly
  - `dot_config/nvim/` — run `nvim --headless "+Lazy! restore" +qa`
  - `private_Library/.../Cursor/User/` — run `cursor --install-extension` directly
  - `data/mise/` — run `mise upgrade` directly

## Scripts

The helper excludes `run_` scripts from STATUS and DIFF, so you will not see them.
That is deliberate: chezmoi runs them on apply by design, an `R` status can never be
file drift, and plain `run_` scripts are pending permanently. Let them run and do not
report them. Reference: https://www.chezmoi.io/reference/target-types/#scripts
