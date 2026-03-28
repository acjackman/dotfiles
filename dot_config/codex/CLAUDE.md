# Codex Config (`~/.config/codex/`)

Codex config is redirected from `~/.codex/` to `~/.config/codex/` via `CODEX_HOME` (set in `zshenv.zsh`).

## Managed Files

- `config.toml` — **GENERATED, do not edit directly.** Edit files in `config.d/` instead.
- `AGENTS.md` — **GENERATED, do not edit directly.** Edit `agents-codex.md` for codex-specific instructions. Shared instructions come from `~/.config/agents/core.md`.
- `agents-codex.md` — Codex-specific global instructions (edit directly)
- `rules/*.md` — Execution policy rules (edit directly)

## Config Assembly

The `run_onchange_after_generate_config-toml.sh.tmpl` script generates two files on `chezmoi apply`:

1. **config.toml** — concatenated from `config.d/*.toml` (numeric prefixes control order). Each file owns distinct TOML keys/tables — do not duplicate keys across files.
2. **AGENTS.md** — concatenated from `~/.config/agents/core.md` + `agents-codex.md`. Codex doesn't support `@` imports, so we assemble at deploy time.

## NOT Tracked (runtime/sensitive)

- `auth.json` — credentials
- `history.jsonl` — command history
- `sessions/` — session transcripts
- `log/` — debug logs
