---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also creates docs (ADRs and glossary) as we go.
disable-model-invocation: true
---

Run a `/grilling` session that also captures what it learns as durable, repo-local docs.

Before grilling, consult the repo's domain docs as described in `~/.claude/skills/eng-setup/domain.md` — read `CONTEXT.md` (the glossary) and the relevant ADRs under `docs/adr/` (resolve the exact paths per that doc) so the interview builds on decisions already made rather than relitigating them. If those files don't exist, proceed silently.

As decisions get resolved during the grilling, use the `/domain-modeling` skill to record them:

- Write each architecture decision as an ADR in the repo (`docs/adr/`, path resolved per `domain.md`) — repo-local, reviewable alongside the code, **not** in any vault.
- Keep `CONTEXT.md` a clean glossary of the domain terms the plan uses. When the interview settles a term's meaning, `/domain-modeling` adds or sharpens its glossary entry; don't let `CONTEXT.md` accumulate narrative or decision logs — those belong in ADRs.

Everything this skill learns is retained in those repo-local files, so a later session can pick up the sharpened understanding without re-grilling.
