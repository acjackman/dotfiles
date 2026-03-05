# Chezmoi and Git Worktrees

This document covers how chezmoi interacts with git worktrees and provides
practical guidance for agents and humans working in this repo.

## How Chezmoi Resolves the Source Directory

Chezmoi has two related path concepts:

- **Source directory** (`-S` / `--source`): Where chezmoi reads source-state
  files (templates, scripts, dot-prefixed files). Default:
  `~/.local/share/chezmoi`
- **Working tree** (`-W` / `--working-tree`): The git working tree for
  operations like `chezmoi git`. Default: same as source directory.

**Key behavior:** `chezmoi apply` always reads from the configured source
directory, regardless of your current working directory. Running
`chezmoi apply` while `cd`'d into a worktree does NOT make it read from that
worktree.

## Pointing Chezmoi at a Worktree

Use `--source` (and optionally `--working-tree`) to override:

```sh
# Preview what a worktree would deploy
chezmoi diff --source ~/.local/share/chezmoi/.worktrees/my-branch

# Apply from a worktree (deploys that branch's files to ~/)
chezmoi apply --source ~/.local/share/chezmoi/.worktrees/my-branch

# Targeted apply of a single file from a worktree
chezmoi apply --source ~/.local/share/chezmoi/.worktrees/my-branch ~/.config/zsh/zshrc.zsh
```

When `--source` is set, chezmoi automatically sets `--working-tree` to match,
so you typically only need `-S`.

There is no `CHEZMOI_SOURCE_DIR` environment variable — the flag is the only
override mechanism.

## Persistent State is Global

Chezmoi stores persistent state in a single BoltDB file at
`~/.config/chezmoi/chezmoistate.boltdb`. This state is **shared across all
worktrees** and includes:

- **`scriptState`**: Tracks `run_onchange_` scripts by content hash. If a
  worktree has identical script content to what was last applied, the script
  won't re-run.
- **`entryState`**: Tracks deployed file hashes for conflict detection.
- **`configState`**: Tracks the config template hash.

### Implications

1. **`run_onchange_` scripts**: Tracked by content SHA256. If you modify a
   `run_onchange_` script in a worktree and apply from it, the new hash is
   recorded globally. Switching back to the main worktree may re-trigger the
   script if its content differs.

2. **Conflict detection**: After applying from worktree A, chezmoi's entry
   state reflects worktree A's files. Applying from the default source (or
   worktree B) may show spurious diffs or prompt for conflicts.

3. **State isolation** is possible with `--persistent-state`:
   ```sh
   chezmoi apply --source .worktrees/my-branch --persistent-state /tmp/chezmoi-test-state.boltdb
   ```
   This prevents worktree testing from polluting the main state. However, this
   state starts empty, so all `run_onchange_` scripts will run.

## Practical Guidance

### For agents working in worktrees

**Prefer `chezmoi diff` over `chezmoi apply` when testing.** Most of the time,
you're editing source files — you don't need to deploy them to verify
correctness. Use diff to confirm the output looks right:

```sh
chezmoi diff --source "$(git rev-parse --show-toplevel)"
```

**If you must apply from a worktree**, use targeted applies for the specific
files you changed:

```sh
chezmoi apply --source "$(git rev-parse --show-toplevel)" ~/.config/specific/file
```

**Do not apply from worktrees routinely.** It pollutes the global persistent
state and may cause `run_onchange_` scripts to re-trigger unexpectedly when the
main branch is applied later.

### Gotchas

1. **Config template warning**: Applying from a worktree that has modified
   `.chezmoi.toml.tmpl` will produce:
   ```
   chezmoi: warning: config file template has changed, run chezmoi init to regenerate config file
   ```
   This is expected — the worktree's template differs from the last `chezmoi
   init`. Don't run `chezmoi init` from a worktree branch.

2. **Pre-read-source-state hook**: The config references
   `.local/share/chezmoi/.install-password-manager.sh` as a relative path. This
   hook runs relative to the home directory, not the source dir, so it works
   fine regardless of which worktree is used as source.

3. **`chezmoi cd`**: This always opens a shell in the default source directory,
   not the current worktree. It's not useful in a worktree context.

4. **`chezmoi edit`**: Similarly uses the default source directory. When
   working in worktrees, edit files directly in the worktree instead.

### Recommended workflow for worktree branches

1. Edit source files in the worktree
2. Use `chezmoi diff --source .` (from worktree root) to preview
3. Use `chezmoi apply --source . <target-path>` for targeted testing
4. Commit, push, and merge to main
5. Run `chezmoi apply` (no flags) from the main source to deploy
