# Issue tracker: Productivity vault

This is the **default** issue tracker for every repo. Tickets, specs, and plans are tracked as
**efforts** in the productivity vault via the `mcp__productivity__*` tools — never as committed
files in the repo. External trackers (Linear, GitHub) are team communication surfaces the agent may
**read and link to, but never write to** — see
[External trackers are read-only for agents](#external-trackers-are-read-only-for-agents).

The engineering skills (`triage`, `to-spec`, `to-tickets`, `wayfinder`, `implement`, …) all read
their tracker operations from this file. If the productivity MCP is not available in a session,
tell the user and stop — do not silently fall back to `gh` or local files.

## The model

| Skill concept | Vault representation |
| --- | --- |
| ticket / issue | an **`effort`** note |
| a plan or spec (PRD) | an **`effort`** whose body holds the spec |
| blocking edge ("blocked by X") | the effort's **`blocked_by`** link |
| parent → child (wayfinder map → tickets) | child's **`efforts`** link points at the parent |
| triage / lifecycle state | the effort's **`effort_status`** (+ tags for sub-roles) |
| external tracker link | the effort's **`linear`** field — a pointer to a *human-authored* ticket |
| architecture decision (ADR) | **repo-local** `docs/adr/` — *not* the vault. See `domain.md`. |

The vault `decision` type is for **cross-cutting / personal** decisions only. Per-codebase ADRs
stay in the repo they govern.

## Resolve the current repo's config

Every skill that tracks work starts by resolving where *this* repo tracks:

1. **Identify the repo.** Get two keys: the **repo root** (`git rev-parse --show-toplevel`,
   which may be `~`-abbreviated to match a note's `local_path`) and the **remote key**
   — `git remote get-url origin` normalised: strip the protocol, any trailing `.git`, and a
   trailing slash, and rewrite `git@host:owner/repo` → `host/owner/repo`
   (e.g. `github.com/moovfinancial/infra`).
2. **Look it up** in the vault, matching on either key:
   `query_typed_notes({ type: "repo", where: 'local_path == "<root>" || remote == "<remote key>"',
   fields: ["frontmatter.*"] })`. Repo notes double as human-readable guides, so also read the body
   (`read_note`) for conventions and gotchas once you've found the note.
3. **If a note exists**, use its fields. **If not**, use these defaults — no note is needed until
   the repo *deviates* from them:

   | field | default |
   | --- | --- |
   | `tracker` | `productivity` |
   | `external_bridge` | `none` |
   | `adr_path` | `docs/adr` |
   | `context_path` | `CONTEXT.md` |
   | `pr_surface` | `false` |

   Global defaults (`linear_org`, `linear_team`, `github_org`, `review_interval`) come from
   `inspect_config` → `workflow`.

4. If the repo has no config note and the user asks to link efforts to an external tracker, or wants a
   non-default ADR path, run `/eng-setup` to create the `repos/<slug>.md` note first.

The agent **always tracks its own work as efforts in the vault** — the effort operations below apply
to every repo. `tracker: none` opts a repo out of agent tracking entirely (rare). There is no
`tracker: linear/github`: the agent never adopts an external tracker as its own, because it never
writes there (see [External trackers are read-only for
agents](#external-trackers-are-read-only-for-agents)).

## Effort operations

**Create a ticket / spec.** `create_effort` — pass `title`, and any of `goal`, `context`,
`next_steps`, `open_questions`, `links`, `priority`, `status`, `slug`, `linear`. It returns the
new effort's path (`efforts/<timestamp>-<slug>.md`). For a spec, put the spec body in via
`effort_append_section` after creation (see `to-spec`). Default `status` is `idea`.

**Read a ticket.** `read_note({ path })`. Metadata only: `get_notes_info`.

**Add / edit body sections.** `effort_append_section({ path, section, content, replace })` — for
`Goal`, `Context`, `Next Steps`, `Acceptance criteria`, `Log`, `Answer`, or any `##` heading.

**Move state.** `update_effort_status({ path, status })` — enforces the transition graph and sets
`review_after` automatically. Never hand-edit `effort_status`.

**Set blocking edges.** After the blockers exist, set the blocked ticket's `blocked_by` with
`update_frontmatter({ path, updates: { blocked_by: ["[[efforts/<blocker>]]", …] } })`. A ticket is
**unblocked** when every effort it lists is closed (`is_closed` / status `done` or `dropped`).

**Set parent.** `update_frontmatter({ path, updates: { efforts: ["[[efforts/<parent>]]"] } })` on
the child — this is how a wayfinder map owns its tickets.

**Stamp priority / external link.** `update_frontmatter` for `priority`, `linear`, `due`,
`scheduled`.

**Comment / log progress.** Append under a `## Log` section with `effort_append_section`, or use
`log_entry` for a timestamped daily-log entry that references the effort.

**Query.** `query_typed_notes({ type: "effort", … })`:
- Frontier (open, unblocked): `status: ["idea","planning"]`, `exclude_terminal: true`, then drop any
  whose `blocked_by` still lists an open effort.
- Needs attention: `review_due: true`, or `status: ["blocked","waiting"]`.
- Children of a map: `where: 'efforts.contains("[[efforts/<map>]]")'`.
- Order by urgency: `order_by: [{ field: "status_priority" }]`.

## Triage state mapping

`effort_status` is the lifecycle. The finer triage roles map on top:

| Triage role | Effort representation |
| --- | --- |
| `needs-triage` (captured, unevaluated) | status `idea` |
| `needs-info` (waiting on reporter) | status `waiting` + tag `needs-info` |
| `ready-for-agent` (AFK-ready) | status `planning` + tag `ready-for-agent` |
| `ready-for-human` | status `planning` + tag `ready-for-human` |
| in progress | status `active` |
| done | status `done` |
| `wontfix` | status `dropped` |
| category | tag `bug` or `enhancement` |

Record tags in frontmatter `tags: [...]` (the effort type doesn't declare `tags`, so validation
emits a benign `strict: warn` — that's expected). Query them with
`query_typed_notes({ type: "effort", grep: "ready-for-agent" })` or a `where` on `tags`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is one effort; its **tickets** are child efforts.

- **Map**: an effort with body sections `## Destination`, `## Notes`, `## Decisions so far`,
  `## Not yet specified`, `## Out of scope`. Tag it `wayfinder-map` so it's discoverable
  (`query_typed_notes({ type: "effort", grep: "wayfinder-map" })`).
- **Child ticket**: an effort whose `efforts` link points at the map, body `## Question`, tagged
  with its type — `wayfinder-research`, `wayfinder-prototype`, `wayfinder-grilling`, or
  `wayfinder-task`.
- **Blocking**: `blocked_by` links, exactly as above. The frontier is the map's open children whose
  `blocked_by` are all closed.
- **Claim**: move the ticket `idea`/`planning` → `active` before any work (its first write). In a
  solo vault this mostly guards against your own parallel sessions.
- **Resolve**: append the answer under `## Answer`, `update_effort_status` → `done`, then append a
  one-line pointer (gist + `[[wikilink]]`) to the map's `## Decisions so far`.
- **Out of scope**: `update_effort_status` → `dropped`, and add one line to the map's
  `## Out of scope`.

## External trackers are read-only for agents

**Linear and GitHub are team communication surfaces — humans author there, not agents.** An effort is
your private tracking; a Linear ticket or GitHub issue is a message to your team. The agent must never
put words in your mouth on that channel.

So the bridge is **read-and-link only**. The agent may:

- **Read** an external ticket to pull its context into an effort (`mcp__claude_ai_Linear__get_issue`,
  `gh issue view`, `gh pr view`).
- **Link** an effort to a ticket **that a human already created** — stamp the effort's `linear` field
  (or a `## Links` entry for GitHub) with the URL. This is a pointer, not a publish.
- **Draft** external text on request — a ticket body, a comment, a status update — and **hand it to
  you to post**. Present it as a block to copy, or leave it in the effort under a `## Draft for
  Linear` heading. The agent does not send it.

The agent must **never**, even with `external_bridge` set or a confirmation prompt:

- create a Linear ticket or GitHub issue (`save_issue`, `gh issue create`),
- post/edit comments, change status, or apply labels on an external ticket,
- close or reopen an external issue/PR.

`external_bridge: linear|github` does **not** authorize writing — it only says which system this
repo's efforts correspond to, so reads and links target the right place and drafts are addressed
correctly. If you catch yourself about to write to an external tracker, stop and draft instead.

`pr_surface: true` means external PRs count as incoming requests for `/triage` — **read** them via
`gh pr view` and land the triage *outcome* as an effort. Never comment on, label, or close the PR.
