# Tuna Config

Tuna (https://tunaformac.com) reads `~/.config/tuna/config.toml`. chezmoi
owns this file: the source is `dot_config/tuna/config.toml.tmpl`, which
concatenates two raw-Tuna-format fragments from `.chezmoitemplates/tuna/`.

## Layout

    .chezmoitemplates/tuna/
    ├── catalogs              ← raw [catalogs] + [[catalogs.globalScopes]]
    ├── bindings              ← raw [[comboMode.bindings]] section
    └── settings              ← raw [hotkeys.*] + [[hotkeys.custom]] + [settings]

    dot_config/tuna/
    ├── config.toml.tmpl                         ← deploys to ~/.config/tuna/config.toml
    ├── shims/                                   ← brain-* executables, deploys to ~/.config/tuna/shims/
    └── run_onchange_after_restart-tuna.sh.tmpl  ← restarts Tuna + writes ConfigSync plist keys on fragment changes

## Workflow

**Edit catalogs:** modify `.chezmoitemplates/tuna/catalogs` then `/apply`.
**Edit bindings:** modify `.chezmoitemplates/tuna/bindings` then `/apply`.
**Edit hotkeys/theme/clipboard hotkey:** modify `.chezmoitemplates/tuna/settings`.

## Per-machine manual setup

A few pieces of state aren't reachable from dotfiles. Do these once on every
new Mac after the first `chezmoi apply`:

- **Launch at Login** — toggle on inside Tuna's preferences. Tuna uses
  `SMAppService.mainApp`, which can only be flipped by Tuna's own code;
  there's no public CLI or AppleScript path to register it externally.
- **Accessibility / Input Monitoring** — grant in System Settings → Privacy
  & Security. Required for global hotkeys to fire.

The Spotlight `cmd+space` conflict is handled automatically by
`dot_config/macos/run_onchange_after_set-hotkeys.sh.tmpl`.

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

## Binding format

Every binding is `id` + optional `key`/`label`/`iconPath` + a `destination`
table. Ids must be unique across the whole tree, including inside groups.

**Group** — nests further bindings:

```toml
[[comboMode.bindings]]
id = 'UUID'
key = 'u'
label = 'UI Tweaks'

    [comboMode.bindings.destination]
    type = 'group'

    [[comboMode.bindings.destination.bindings]]
    # …children, each nesting one level deeper
```

**Open an app / run a shell command** — a `command` destination wrapping a
saved command:

```toml
    [comboMode.bindings.destination]
    type = 'command'

        [comboMode.bindings.destination.command]
        actionIdentifier = 'tuna.common-actions/open'
        behavior = 'run'
        presentation = 'automatic'
        subjectIdentifiers = [ 'tuna.applications//Applications/Ghostty.app' ]
        type = 'savedCommand'
```

| Action kind   | `subjectIdentifiers` entry                    | `actionIdentifier`                             |
|---------------|-----------------------------------------------|------------------------------------------------|
| Open an app   | `tuna.applications/<absolute path>`           | `tuna.common-actions/open`                     |
| Shell command | `text:<command line>`                         | `tuna.common-actions/run-text-as-shell-command` |

App subjects are catalog-scoped, so the identifier contains a double slash:
`tuna.applications/` + `/Applications/Ghostty.app`.

**Open a URL** — *not* a command; its own destination type:

```toml
    [comboMode.bindings.destination]
    type = 'url'

        [comboMode.bindings.destination.url]
        relative = 'hammerspoon://rotate-wallpapers'
```

There is also a `route` type for Tuna's internal screens; let the UI generate
those. In general the easiest way to author a new binding is still to add it
through Tuna's Combo Mode editor, then copy the stanza out of
`~/.config/tuna/config.toml` into the fragment.

## Catalogs

`[catalogs]` carries three arrays — `globalScopes`, `searchPriorities`,
`sortOrders` — all currently empty. Older configs wrote `globalScopes` entries
shaped `catalogIdentifier` + `mode` + `selectedItemKeys` to keep catalogs out
of global search. That shape is dead: `selectedItemKeys` no longer exists in
the app at all, `mode` is rejected, and leaving them in place fails the whole
migration with `UnknownLegacyConfigurationFieldError`.

Previously excluded (`mode = 'none'`), with their modern catalog ids:

| Legacy identifier              | Modern id      |
|--------------------------------|----------------|
| `Tuna.EffectsCatalog`          | `tuna.effects` |
| `TunaEmoji.EmojiCatalog`       | `tuna.emoji`   |
| `TunaSystem.AllWindowsCatalog` | `tuna.windows` |

To restore those exclusions, set the global-search scope for the three
catalogs in Tuna's settings, then copy the `[catalogs]` block Tuna writes back
into `.chezmoitemplates/tuna/catalogs`.

## Keeping the fragments drift-free

Tuna rewrites `config.toml` from its in-memory state (on quit, on UI edits,
after a migration), which **normalises indentation and strips comments**. So
the fragments must hold Tuna's exact output and stay comment-free — put
explanation in this file instead. Anything else shows up forever in
`chezmoi diff`. Note there is no `schemaVersion` key: Tuna removes it once a
config is on the current schema.

To re-sync the fragments after a UI change, split the deployed file back into
the three fragments at the `[[comboMode.bindings]]` and `[hotkeys.` boundaries,
re-escaping `{{input}}` in the smart-link templates as `{{ "{{input}}" }}` so
chezmoi doesn't eat it.

### Schema history

Tuna ≤ schemaVersion 1 used a flat `[[comboMode.bindings.children]]` tree with
a single `url = 'tuna://run/<type>.<double-encoded>/<action label>'` per leaf.
schemaVersion 4 replaced `children` with `destination`. Tuna's migrator cannot
read the old shape — it fails with `Unknown keys: children` and **silently
drops every leaf binding**, leaving the group shells behind. If that happens
again, Tuna writes a timestamped `config.toml.backup-*` next to the config
before rewriting it.

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
