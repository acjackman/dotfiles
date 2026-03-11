# Karabiner-Elements Config (Goku)

Karabiner-Elements keybindings are defined in [Goku](https://github.com/yqrashawn/GokuRakujo):

| File | Purpose |
|------|---------|
| `data/karabiner/karabiner.edn` | Goku EDN source (the file you edit) |
| `~/.config/karabiner/karabiner.json` | Compiled output (never edit directly) |
| `run_onchange_after_compile-goku.sh.tmpl` | Auto-compiles EDN → JSON on `chezmoi apply` |

## Applying Changes

The `run_onchange_` script detects EDN changes via checksum and runs `goku` automatically during `chezmoi apply`.

### Worktree Apply

**Do not use `chezmoi apply` for karabiner from a worktree.** The `run_onchange_` script updates global persistent state (`chezmoistate.boltdb`), causing it to re-trigger when you later apply from the default source.

Instead, run goku directly against the worktree's EDN file:

```sh
GOKU_EDN_CONFIG_FILE="$(git rev-parse --show-toplevel)/data/karabiner/karabiner.edn" goku
```

This compiles the config without touching chezmoi state.

## EDN Syntax

Rules live in the `:main` vector as `{:des "..." :rules [...]}` blocks. See [Goku tutorial](https://github.com/yqrashawn/GokuRakujoushi/blob/master/tutorial.md) for syntax.
