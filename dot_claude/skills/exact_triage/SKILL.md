---
name: triage
description: Move incoming requests through a state machine of triage roles — categorise, verify, grill if needed, and write agent-ready briefs. Requests are tracked as efforts in the productivity vault; external issues/PRs are pulled in only where a repo opts into an external request surface.
disable-model-invocation: true
---

# Triage

Move incoming requests through a small state machine of triage roles. A request is tracked as an
**effort** in the productivity vault. The un-triaged inbox is efforts in **`idea`** status.

Read `~/.claude/skills/eng-setup/productivity-tracker.md` — especially **Triage state mapping** — for
how the roles below map onto `effort_status` and tags, and to resolve this repo's config.
`~/.claude/skills/eng-setup/domain.md` covers domain docs.

**External request surfaces.** By default triage works the vault only. If the repo's config sets
`external_bridge` or `pr_surface: true`, triage also pulls in **external** issues/PRs (a PR is an
issue with attached code — same roles, same states, with the deltas marked "for a PR" below). **Read**
them via `gh`/`glab`/the Linear tools, and **land the triage outcome as an effort** — the effort is
the source of truth. **Never post back to the external tracker** — Linear/GitHub are team
communication surfaces, and triage decisions are yours, not the agent's, to announce there. If you
want to reply on the external ticket, the agent drafts the comment and hands it to you to post (see
productivity-tracker.md → *External trackers are read-only for agents*).

## Reference docs

- [AGENT-BRIEF.md](AGENT-BRIEF.md) — how to write durable agent briefs
- [OUT-OF-SCOPE.md](OUT-OF-SCOPE.md) — how rejected enhancements are recorded as dropped efforts

## Roles

Two **category** roles (recorded as tags): `bug`, `enhancement`.

Five **state** roles, mapped to `effort_status` (+ a tag where the status alone is ambiguous):

- `needs-triage` → status `idea` — needs evaluation
- `needs-info` → status `waiting` + tag `needs-info` — waiting on the reporter
- `ready-for-agent` → status `planning` + tag `ready-for-agent` — fully specified, AFK-ready
- `ready-for-human` → status `planning` + tag `ready-for-human` — needs human implementation
- `wontfix` → status `dropped`

For a PR, the same states read against the attached code: `ready-for-agent` means a brief is attached
and an agent should take the next step on the diff; `ready-for-human` means it's ready for a human to
merge.

Every triaged effort should carry exactly one category tag and sit in one state. If the state looks
wrong, flag it and ask before doing anything else.

State transitions follow the effort graph: an `idea` moves to `waiting` (needs-info), `planning`
(ready-for-*), or `dropped` (wontfix). `waiting` returns to `idea`/`planning` once the reporter
replies. Flag transitions that look unusual and ask before proceeding.

## Invocation

The maintainer invokes `/triage` and describes what they want in natural language. Interpret and act.
Examples:

- "Show me anything that needs my attention"
- "Let's look at <effort>" (or an external `#42` where a surface is configured)
- "Move <effort> to ready-for-agent"
- "What's ready for agents to pick up?"

## Show what needs attention

Query the vault and present three buckets, oldest first:

1. **`idea`** — never triaged (`query_typed_notes({ type: "effort", status: "idea" })`).
2. **`waiting` + `needs-info`** where the reporter has replied since the last triage notes — needs
   re-evaluation.
3. **In-flight** — `blocked` / stale `waiting` worth a look (`review_due: true`).

When an external surface is in scope, include external issues/PRs in these buckets and tag each line
`[PR]` or `[issue]` and `[external]`. Discovery surfaces only *external* PRs (the config defines who
counts as external) — a collaborator's in-flight PR is not triage work. An explicitly named PR is
always triaged regardless of author.

Show counts and a one-line summary per item. Let the maintainer pick.

## Triage a specific request

1. **Gather context.** Read the full effort (or external issue/PR — body, comments, labels, author,
   dates; for a PR, the diff too). Parse any prior triage notes in the body so you don't re-ask
   resolved questions. Explore the codebase using the project's domain glossary, respecting ADRs.
   Run two checks: (a) **redundancy** — search for an existing implementation of the requested
   behavior by domain concept (not just the request's wording), and report where you looked; if
   found, it's an already-implemented `wontfix` (step 5). (b) **prior rejection** — query dropped
   efforts tagged `out-of-scope` and surface any that resembles this request (see OUT-OF-SCOPE.md).

2. **Recommend.** Tell the maintainer your category and state recommendation with reasoning, plus a
   brief codebase summary — including whether it's already implemented. Wait for direction.

3. **Verify the claim.** Before any grilling, check the claim holds up. For a bug, reproduce it from
   the reporter's steps. For a PR, confirm the diff does what it claims — check it out, run the
   relevant tests. Report what happened: confirmed (with code path), failed, or insufficient detail
   (a strong `needs-info` signal). A confirmed verification makes a much stronger agent brief.

4. **Grill (if needed).** If the request needs fleshing out, run `/grilling` and `/domain-modeling`
   together — grill it into shape one question at a time, sharpening domain terms and updating
   `CONTEXT.md`/ADRs inline as decisions land.

5. **Apply the outcome** — write to the effort, then set its status:
   - `ready-for-agent` — write the agent brief into the effort body under `## Agent brief`
     ([AGENT-BRIEF.md](AGENT-BRIEF.md)); status `planning` + tag `ready-for-agent`.
   - `ready-for-human` — same brief structure, but note why it can't be delegated (judgment calls,
     external access, design decisions, manual testing); status `planning` + tag `ready-for-human`.
   - `needs-info` — append triage notes (template below); status `waiting` + tag `needs-info`.
   - `wontfix`:
     - **Already implemented** — point to where it lives in a `## Resolution` note; status `dropped`.
       Do **not** record it as out-of-scope (that KB is for *rejected* requests, not built ones).
     - **Rejected (bug)** — brief explanation in a `## Resolution` note; status `dropped`.
     - **Rejected (enhancement)** — record it as an out-of-scope dropped effort
       ([OUT-OF-SCOPE.md](OUT-OF-SCOPE.md)); status `dropped` + tag `out-of-scope`.
   - `needs-triage` — leave it `idea`. Optional note if there's partial progress.

   If the request came from an external surface, do **not** post the decision back yourself. If you
   want to respond there, draft the comment and hand it to the maintainer to post.

## Quick state override

If the maintainer says "move <effort> to ready-for-agent", trust them and apply it directly. Confirm
what you're about to do (status change, tags, body note), then act. Skip grilling. If moving to
`ready-for-agent` without a grilling session, ask whether they want an agent brief.

## Needs-info template

Append under a `## Triage Notes` section of the effort:

```markdown
## Triage Notes

**What we've established so far:**

- point 1
- point 2

**What we still need from you (@reporter):**

- question 1
- question 2
```

Capture everything resolved during grilling under "established so far" so the work isn't lost.
Questions must be specific and actionable, not "please provide more info".

## Resuming a previous session

If prior triage notes exist on the effort, read them, check whether the reporter has answered any
outstanding questions, and present an updated picture before continuing. Don't re-ask resolved
questions.
