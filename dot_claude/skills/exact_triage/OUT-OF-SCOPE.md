# Out-of-scope records

Rejected **enhancement** requests are kept as **dropped efforts tagged `out-of-scope`** in the
productivity vault — not as files in the repo. They serve two purposes:

1. **Institutional memory** — why a feature was rejected, so the reasoning isn't lost.
2. **Deduplication** — when a new request matches a prior rejection, triage surfaces the previous
   decision instead of re-litigating it.

## The record

One effort per **concept**, not per request. Multiple requests for the same thing are grouped under
one effort.

- **Status**: `dropped` (`update_effort_status`).
- **Tag**: `out-of-scope` in frontmatter — this is what triage queries.
- **Title**: a short, recognizable concept name (e.g. "Dark mode", "Plugin system", "GraphQL API").
- **Body**: written like a short design note, not a database row. Use these sections:

```markdown
## Decision

Out of scope: <one line>.

## Why this is out of scope

<Substantive reasoning — project scope/philosophy, technical constraints, or a strategic decision.
Paragraphs, code samples, examples. Durable: don't reference temporary circumstances like "too busy
right now" — those are deferrals, not rejections.>

## Prior requests

- <link or reference to each request that asked for this — effort wikilink, or an external issue URL>
```

### Writing the reason

Substantive, not "we don't want this". Good reasons reference project scope/philosophy ("this project
focuses on X; theming is a downstream concern"), technical constraints ("would require Y, which
conflicts with our Z architecture"), or a strategic decision ("we chose A over B because…"). Durable,
not circumstantial.

## When to check for prior rejections

During triage (*Gather context*), query them:
`query_typed_notes({ type: "effort", status: "dropped", grep: "out-of-scope" })` (or a `where` on
`tags`). When evaluating a new request:

- Check whether it matches an existing out-of-scope concept — by concept similarity, not keyword
  ("night theme" matches "Dark mode").
- If there's a match, surface it: "This is similar to the dropped effort *Dark mode* — we rejected
  this before because [reason]. Do you still feel the same way?"

The maintainer may:

- **Confirm** — append the new request to the existing effort's "Prior requests", then drop the new
  request (or fold it into the existing record).
- **Reconsider** — reopen the out-of-scope effort (`update_effort_status` off `dropped` isn't allowed
  by the graph, so create a fresh effort for the reconsidered work and note it supersedes the old
  record), and let the request proceed through normal triage.
- **Disagree** — related but distinct; proceed with normal triage.

## When to write an out-of-scope record

Only when an **enhancement** (not a bug) is *rejected* as `wontfix`. Applies to enhancement PRs
exactly as to requests — a rejected PR is recorded so the same request doesn't return as fresh code.

Do **not** record something dropped because it's **already implemented**. That's a built feature, not
a rejected one; recording it would poison the dedup checks. Instead, the effort's `## Resolution`
note points to where the feature already lives.

The flow:

1. Maintainer decides a request is out of scope.
2. Query for a matching out-of-scope effort.
3. If one exists: append the new request to its "Prior requests".
4. If not: set the effort's title to the concept, write the Decision/Why/Prior-requests body, tag it
   `out-of-scope`, and set status `dropped`.

## Changing your mind later

If the maintainer reconsiders a previously rejected concept, the historical dropped effort stays as
the record — create a fresh effort for the new work rather than resurrecting the old one, and note in
the new effort that it supersedes the earlier out-of-scope record.
