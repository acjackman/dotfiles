# Domain docs

How the engineering skills consume a repo's domain documentation and where architecture decisions
live. Resolve the repo's config first (see `productivity-tracker.md` → *Resolve the current repo's
config*) — `context_path` and `adr_path` come from there, defaulting to `CONTEXT.md` and `docs/adr`.

## ADRs live in the repo, not the vault

Architecture decisions are **code-coupled**: they belong under version control with the code they
govern, reviewable in the same PR. They live in the repo at `<adr_path>` (default `docs/adr/`) — one
markdown file per decision, numbered (`0001-…md`). The `/domain-modeling` skill writes them there.

The vault `decision` type is **not** used for per-codebase ADRs. Reserve it for cross-cutting or
personal decisions that don't belong to any single repo.

## Before exploring, read these

- **`<context_path>`** (default `CONTEXT.md`) at the repo root — the domain glossary. Or
  **`CONTEXT-MAP.md`** if it exists, which points at one `CONTEXT.md` per context (multi-context
  repos, typically monorepos) — read each one relevant to the topic.
- **`<adr_path>/`** (default `docs/adr/`) — read ADRs touching the area you're about to work in. In
  multi-context repos, also check `src/<context>/docs/adr/`.

If any of these don't exist, **proceed silently**. Don't flag their absence or suggest creating them
upfront. `/domain-modeling` creates them lazily when terms or decisions actually get resolved.

## Use the glossary's vocabulary

When your output names a domain concept (an effort title, a refactor proposal, a hypothesis, a test
name), use the term as defined in the glossary. Don't drift to synonyms it explicitly avoids. If the
concept isn't in the glossary yet, that's a signal — either you're inventing language the project
doesn't use (reconsider), or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders) — but worth reopening because…_
