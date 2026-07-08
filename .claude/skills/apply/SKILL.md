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
- Status **"R" always means a `run_` script will EXECUTE** — it is never a file being created or "recreated". Do not read `R` as file drift. See "Understanding `run_` scripts" below.
- Never modify deployed files directly — always edit the chezmoi source
- **Some configs have special apply instructions** (especially for worktrees). Check the directory's `CLAUDE.md` before applying. Known configs with `data/`-sourced `run_onchange_` scripts that pollute state from worktrees:
  - `data/karabiner/` — run `goku` directly
  - `dot_config/nvim/` — run `nvim --headless "+Lazy! restore" +qa`
  - `private_Library/.../Cursor/User/` — run `cursor --install-extension` directly
  - `data/mise/` — run `mise upgrade` directly

## Understanding `run_` scripts

chezmoi source files whose name starts with `run_` are **scripts, not managed files**. A plain `chezmoi apply` runs them **by design** — this is expected behavior, not drift and not something that "showed up" unexpectedly. When one executes during an apply, treat it as normal; do **not** stop-and-flag it the way you would an unexpected file diff.

**How they show in `chezmoi status`:** with status letter **`R`** ("Run"), and the target path is the script name with the `run_` prefix stripped (e.g. source `dot_kube/run_set_kube_config_permissions.sh` → status shows `R .kube/set_kube_config_permissions.sh`). This is easy to misread as a file being created/recreated — it is not. Regular managed files show `A` (add), `M` (modify), or `D` (delete); only scripts show `R`.

**Naming controls when/how often they run:**
- `run_<name>` — runs on **every** apply.
- `run_once_<name>` — runs **once ever** per machine (tracked in `chezmoistate.boltdb`); typically install/migration steps.
- `run_onchange_<name>` — runs whenever the script's rendered content (usually a `# hash:` of the file it watches) changes. Most of Adam's scripts are these: they re-run only when the thing they configure changed.
- `run_before_<name>` / `run_after_<name>` — ordering relative to file updates in the same apply (before = runs before files are written, after = runs after).

These combine, e.g. `run_onchange_after_setup-herdr.sh.tmpl` = "after files are written, when its watched hash changed."

### Adam's actual `run_` scripts (the ones you'll most often see on apply)

Most are `.tmpl` (chezmoi-templated). All are idempotent and safe to let run on a normal apply:

- **`dot_config/herdr/run_onchange_after_setup-herdr.sh.tmpl`** — after `herdr/config.toml` changes: ensures herdr plugins are installed, then `herdr server reload-config` on the running server. Guarded on `herdr` being installed (clean no-op otherwise). Reload is live and non-destructive — it does not drop sessions/workspaces.
- **`dot_config/worktrunk/run_onchange_after_merge-worktrunk-config.py.tmpl`** — merges the chezmoi-managed worktrunk settings with the machine-local `[projects]` section so local project pins are preserved. Pure config-file merge.
- **`dot_config/homebrew/run_onchange_darwin-install-packages.sh.tmpl`** — runs `brew bundle` for the active Brewfiles (with tap-trust management). Installs/updates packages; expected on Brewfile changes.
- **`dot_claude/run_onchange_after_generate_settings.sh.tmpl`** → target `.claude/generate_settings.sh` — regenerates `~/.claude/settings.json` (and per-profile settings) from the declarative permissions/hooks/statusline sources. Idempotent regeneration.
- **`dot_kube/run_set_kube_config_permissions.sh`** → target `.kube/set_kube_config_permissions.sh` — `chmod 600 ~/.kube/config` if it exists and isn't already 0600. Trivial permission fix.
- **`dot_local/share/wallpapers/run_after_install-pre-commit.sh`** → target `.local/share/wallpapers/install-pre-commit.sh` — installs pre-commit hooks in wallpaper git repos and warns about uncommitted/unpushed changes. Read-mostly, safe.

Other `run_once_*` scripts exist for one-time setup/migration (gh extensions, 1Password SSH agent, vault migration, etc.); by definition they only fire once per machine.

**Bottom line for `/apply`:** if the only "surprises" are `R`-status entries, that's `run_` scripts doing their job. Preview them (the info script's WARNINGS section lists which will execute), let them run, and confirm the thing they configure is healthy afterward (e.g. `herdr status server` + `clank list` after the herdr reload).
