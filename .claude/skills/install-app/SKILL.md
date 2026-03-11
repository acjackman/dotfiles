---
name: install-app
description: Install and configure a new macOS application in the chezmoi dotfiles repo. Use when the user says "install app", "add app", "set up <app>", or wants to integrate a new application into the dotfiles.
---

# Install App

Guide for installing a new macOS application and integrating it into this chezmoi dotfiles repo.

## Arguments

$ARGUMENTS should contain the application name and optionally any notes about desired configuration.

## Instructions

Work through each phase in order. Commit after completing each phase. Skip phases that don't apply to the app.

### Phase 1: Installation

1. **Add to Brewfile** — determine if the app belongs in `dot_config/homebrew/Brewfile-base` (all machines) or a machine-specific Brewfile. Add the `cask`, `brew`, or `mas` entry. Add any needed `tap` lines.

2. **Check removal lists** — search `.chezmoiremove` and any uninstall/cleanup scripts for references to the app. Remove entries that would conflict with the new installation.

3. **Install** — run `brew install` or `brew install --cask` to install the app immediately.

4. **Apply** — use `/apply` targeting just the Brewfile to deploy the change.

### Phase 2: Configuration

1. **Find config location** — check where the app stores its configuration:
   - `~/.config/<app>/` — manage directly via chezmoi in `dot_config/`
   - `~/Library/Application Support/<app>/` — use chezmoi's `private_Library/` or a `run_onchange_` deploy script
   - `~/Library/Preferences/` (plist) — manage via `defaults write` in the darwin-defaults script
   - Custom location — create a symlink or deploy script as needed

2. **Create chezmoi source files** — add config files under the appropriate chezmoi source directory. Use correct prefixes: `dot_`, `private_`, `executable_`, `symlink_`.

3. **Data files** — if config references reusable data (lists, mappings, etc.), store them in `data/` and use chezmoi templates to reference them.

4. **Deploy scripts** — if the app reads config from a location chezmoi can't directly target (e.g., `~/Library/Application Support/`), create a `run_onchange_` script to copy/deploy the config. Use a hash comment so chezmoi detects content changes:

   ```bash
   # config hash: {{ include "path/to/config" | sha256sum }}
   ```

5. **Apply** — use `/apply` targeting the specific config paths to deploy and verify.

### Phase 3: Integration

Check each integration point and add config where relevant:

- **Aerospace** (`dot_config/aerospace/`): Add `on-window-detected` rules for window management (floating, workspace assignment, etc.). Check the app's `app-id` with: `mdls -name kMDItemCFBundleIdentifier /Applications/<App>.app`
- **Sketchybar** (`dot_config/sketchybar/`): Add status bar items or plugins if the app has state worth displaying
- **Leader Key** (`dot_config/leader-key/`): Add launch/toggle keybindings under appropriate groups
- **Karabiner/Goku** (`dot_config/karabiner/`): Add keyboard shortcuts or modifier rules
- **PATH** (`dot_local/bin/`): If the app bundles a CLI tool, create a symlink so it's on PATH: `symlink_toolname` pointing to the app's binary
- **Shell** (`dot_config/zsh/`): Add aliases, completions, or environment variables if needed

Apply each integration change with `/apply` targeting the specific config.

### Phase 4: Utility Scripts

If the app benefits from helper scripts for common operations:

1. Create scripts in `dot_local/bin/` with the `,` prefix convention (e.g., `,app-do-thing`)
2. Use the `executable_` chezmoi prefix so they're deployed with execute permissions
3. Apply with `/apply`

### Phase 5: Documentation

Create a `CLAUDE.md` in the app's config directory (e.g., `dot_config/<app>/CLAUDE.md`) covering:

- What the app does and where config files live
- Key settings and what they control
- Related configs in other directories (aerospace rules, sketchybar items, etc.)
- CLI usage if applicable
- Common operations and troubleshooting

### Phase 6: macOS Defaults

Check if the app needs `defaults write` commands:

1. Search for existing defaults: `defaults read <app-bundle-id>` or `defaults find <app-name>`
2. Add needed defaults to `run_onchange_darwin-defaults.sh.tmpl`
3. Check for conflicts with existing system shortcuts (especially keyboard shortcuts the app needs)
4. Apply with `/apply`

## Important

- Always use `/apply` to deploy changes — never `chezmoi apply --force`
- When in a worktree, use targeted applies (specific file/directory paths) rather than broad applies
- Test each phase before moving to the next — launch the app, verify config is loaded
- Follow chezmoi naming conventions: `dot_`, `private_`, `executable_`, `symlink_`, `run_onchange_`
- Store reusable data in `data/`, not inline in config files
- Check `.chezmoiexternal.toml` for patterns on managing external dependencies (themes, plugins)
- Read existing `CLAUDE.md` files in related config directories before modifying those configs
