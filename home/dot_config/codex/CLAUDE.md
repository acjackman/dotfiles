# Codex Config (`~/.config/codex/`)

Codex config is redirected from `~/.codex/` to `~/.config/codex/` via `CODEX_HOME` (set in `zshenv.zsh`).

## Managed Files

- `config.toml` — **co-owned with Codex**, rendered by `modify_private_config.toml`. Edit the fragments in `.chezmoitemplates/codex/` (at the chezmoi source root, `home/`), not this directory. See [config.toml](#configtoml).
- `AGENTS.md` — **GENERATED, do not edit directly.** Edit `agents-codex.md` for codex-specific instructions. Shared instructions come from `~/.config/agents/core.md`.
- `agents-codex.md` — Codex-specific global instructions (edit directly)
- `rules/*.md` — Execution policy rules (edit directly)

## config.toml

`modify_private_config.toml` is a chezmoi **modify template** (same pattern as
`dot_config/herdr/modify_config.toml`). Codex writes runtime state back into
`config.toml`, so the file has two owners:

- **Managed keys (ours)** — every fragment in `.chezmoitemplates/codex/*.toml`,
  rendered as a template (so `{{ .chezmoi.homeDir }}` works) and joined in
  filename order. Numeric prefixes control order. Each fragment owns distinct
  keys/tables — TOML allows each table once.
- **Runtime tables (Codex's)** — `[projects.*]` (trust), `[hooks.state.*]`
  (hook trust hashes), `[tui]` / `[tui.*]` (nux counters), `[notice]` /
  `[notice.*]`. Lifted verbatim from the live file on every apply/diff and
  appended after the fragments. Never define these in a fragment: the render
  fails on the duplicate table.

Anything else Codex writes — `model` / `model_reasoning_effort` via `/model`,
`[mcp_servers.*]` via `codex mcp add`, a feature toggle — is **not** carried
over. It shows up in `chezmoi diff ~/.config/codex/config.toml` as drift: adopt
it into a fragment, or let apply revert it. If Codex starts writing a new
runtime-only table, add its name to `$runtime` at the top of the template.

The template ends with `fromToml` on its own output, so invalid TOML fails the
render (and the apply) instead of reaching Codex. Lifted blocks drop
comment-only lines: Codex (toml_edit) attaches the next table's leading
comments to the previous table, and keeping them would duplicate fragment
comments.

Preview with `chezmoi cat ~/.config/codex/config.toml`. Target is `private_`
(0600) because Codex writes it 0600.

## AGENTS.md

`run_onchange_after_generate-agents-md.sh.tmpl` concatenates
`~/.config/agents/core.md` + `agents-codex.md` on apply. Codex doesn't support
`@` imports, so we assemble at deploy time.

## herdr integration

`hooks.json` and `herdr-agent-state.sh` here are written by `herdr integration
install codex` (driven by `dot_config/herdr/run_after_ensure-herdr-integrations.sh`)
and are not tracked. Its required `[features] hooks = true` lives in
`.chezmoitemplates/codex/10-features.toml` — keep it there, or apply reverts it.

## NOT Tracked (runtime/sensitive)

- `auth.json` — credentials
- `history.jsonl` — command history
- `sessions/` — session transcripts
- `log/` — debug logs
- `~/.local/state/dotfiles/replaced/codex/` — copies the old concatenating generator saved before each rebuild (moved there by `run_once_before_migrate-replaced-copies.sh`). Nothing writes new ones; review and delete.
