# Tuna Config

Tuna (https://tunaformac.com) reads `~/.config/tuna/config.toml`. chezmoi
owns this file: the source is `dot_config/tuna/config.toml.tmpl`, which
concatenates two raw-Tuna-format fragments from `.chezmoitemplates/tuna/`.

## Layout

    .chezmoitemplates/tuna/
    ├── bindings              ← raw [[comboMode.bindings]] section
    └── settings              ← raw [hotkeys.*] + [[hotkeys.custom]] + [settings]

    dot_config/tuna/
    ├── config.toml.tmpl                              ← deploys to ~/.config/tuna/config.toml
    ├── shims/                                        ← brain-* executables, deploys to ~/.config/tuna/shims/
    ├── run_once_after_register-tuna-loginitem.sh.tmpl ← adds Tuna to macOS login items (per-machine)
    └── run_onchange_after_restart-tuna.sh.tmpl       ← restarts Tuna + writes ConfigSync plist keys on fragment changes

## Workflow

**Edit bindings:** modify `.chezmoitemplates/tuna/bindings` then `/apply`.
**Edit hotkeys/theme/clipboard hotkey:** modify `.chezmoitemplates/tuna/settings`.

## Drift detection (UI-driven changes)

Because chezmoi owns the deployed file, anything Tuna's UI writes that
diverges from the templates shows up as `chezmoi diff`. To backport a
UI change into source:

```sh
chezmoi diff dot_config/tuna             # see what differs
chezmoi merge ~/.config/tuna/config.toml # interactive 3-way merge
# …then split the merged content back into the bindings/settings fragments.
```

Or just inspect the diff and hand-edit the right fragment.

## URL encoding

Combo-mode action URLs use Tuna's native format:

    tuna://run/<type>.<DOUBLE-URL-encoded-value>/<URL-encoded-action-label>

| Action kind   | type   | action label                  |
|---------------|--------|-------------------------------|
| Open an app   | `path` | `Open`                        |
| Shell command | `text` | `Run%20Text%20as%20Shell%20Command` |
| Open a URL    | `url`  | `Open%20URL`                  |

The value is URL-encoded **twice**. Characters that stay literal:
`A-Za-z0-9-_.~` plus `!$&'()*+,:;=@` (Swift's `urlPathAllowed` minus `/`).
Easiest way to author a new binding: add it through Tuna's UI, then copy
the line out of `~/.config/tuna/config.toml` into the fragment.

## Restart behavior

Tuna doesn't watch its own config file. The
`run_onchange_after_restart-tuna.sh.tmpl` script computes a hash of both
fragments at chezmoi-template time and re-runs whenever either changes,
quitting + relaunching Tuna so new bindings/hotkeys take effect.

While Tuna is stopped, the same script also writes
`com.brnbw.Tuna.ConfigSyncCustomFolderPath` and `ConfigSyncUsesCustomFolder`
so Tuna reads `~/.config/tuna/config.toml` instead of its default
Application Support location. Those keys live in the plist, not the
config.toml, so a fresh machine would otherwise ignore the deployed config.
