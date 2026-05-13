# Tuna Config

Tuna (https://tunaformac.com) reads `~/.config/tuna/config.toml`, but that
file is **generated** — never edit it directly. The generator script writes
it on every `chezmoi apply` and on hand-runs of /apply.

After editing anything under `sources/`, run `/apply`. The
`run_onchange_after_generate_config.py.tmpl` script merges the v2-tree binding
sources, prepends `schemaVersion`, appends `sources/settings.toml`, writes
the result to `~/.config/tuna/config.toml`, and restarts Tuna.

## Layout

- `sources/config.toml` — top-level binding tree.
- `sources/notes.toml.tmpl` — Brain/notes leader sub-tree (templated for
  vault name).
- `sources/settings.toml` — seed for `[hotkeys.*]` + `[settings]` used only
  on fresh installs. After the first run Tuna owns those tables; the
  generator preserves whatever Tuna last wrote so UI-driven theme/hotkey
  changes survive `chezmoi apply`. NOT merged into the binding tree.
- `shims/` — small executables placed on `PATH` so leader bindings can
  invoke `brain-log`, `brain-capture`, etc. as plain commands.
- `run_onchange_after_generate_config.py.tmpl` — the generator. Re-runs
  whenever any source `*.toml` (except `settings.toml`) changes.

The deployed structure on disk is:

    ~/.config/tuna/
    ├── config.toml     ← GENERATED (do not edit)
    ├── sources/        ← chezmoi-managed v2 sources
    └── shims/

Sources live in a subdir so chezmoi doesn't deploy a v2 TOML on top of
Tuna's own `config.toml`.

## Source format (v2 nested map)

```toml
[t]
rank = 10                       # lower sorts earlier among siblings

[t.children.n]
label = "New Window + Sesh"     # group / leaf label

[t.children.n.action]
rank = 20
kind = "command"                # "application" | "command" | "url"
value = "~/.config/ghostty/ghostty-sesh"
iconPath = "/Applications/Ghostty.app"   # optional, leaf-only
```

A node is a **group** if it has `children`, a **leaf** if it has `action`.
Mixing both on one node is rejected. `rank` may be set on either the node
or the action; lower sorts first, ties broken by label then key.

Set `disabled = true` to omit a node from the emitted config.

Multiple files in this directory are merged: children deep-merge by key,
labels prefer non-empty overrides, actions override.

## Output format (Tuna's TOML)

Each `kind` maps to a `tuna://run/<type>.<value>/<action>` URL:

| kind          | type   | action label                  |
|---------------|--------|-------------------------------|
| `application` | `path` | `Open`                        |
| `command`     | `text` | `Run Text as Shell Command`   |
| `url`         | `url`  | `Open URL`                    |

The action's `value` is URL-encoded **twice** (only `A-Za-z0-9-_.~` plus
`!$&'()*+,:;=@` stay literal — matches Swift's `urlPathAllowed` minus `/`).
The action label is URL-encoded once.

Round-trip is validated against Tuna's own writer; if you add a new `kind`
or hit an encoding mismatch, update `_URL_SAFE` / `_KIND_TO_TUNA` in the
generator and re-test against a hand-written `~/.config/tuna/config.toml`.

## Migration footnote

Quitting Leader Key + Alfred (and removing their stale state) is handled by
the separate `run_once_after_migrate-to-tuna.sh.tmpl` at the repo root, not
by this generator. The generator only owns the Tuna config file and Tuna
restarts.
