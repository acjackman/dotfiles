---
name: eng-setup
description: Configure how a repo is tracked by the engineering skills — whether its efforts link to an external tracker (read-only) and where its ADRs live. Writes a per-repo config note to the productivity vault. Run only when a repo needs to deviate from the defaults.
disable-model-invocation: true
---

# Engineering skills setup

The engineering skills track work as **efforts in the productivity vault** by default — no per-repo
setup needed. Run this skill only when a repo **deviates** from the defaults:

| Default | Override with this skill when… |
| --- | --- |
| no external bridge | efforts here correspond to Linear/GitHub tickets you want to read & link (the agent still never writes there) |
| ADRs in `docs/adr/` | this repo keeps ADRs somewhere else |
| glossary in `CONTEXT.md` | this repo's glossary lives elsewhere, or it's multi-context |
| PRs are not a request surface | external PRs should flow through `/triage` (read-only) |

The full model lives in [productivity-tracker.md](productivity-tracker.md) and
[domain.md](domain.md). This skill just writes the `repos/<slug>.md` config note those docs resolve.

## Process

This is prompt-driven — explore, present, confirm, then write. Assume the user may not remember the
field names; explain each choice briefly.

### 1. Explore

- Get the repo root (`git rev-parse --show-toplevel`, `~`-abbreviated) and the remote key
  (`git remote get-url origin`, normalised — see productivity-tracker.md → *Resolve the current
  repo's config*, step 1).
- Check the vault for an existing note:
  `query_typed_notes({ type: "repo", where: 'local_path == "<root>" || remote == "<remote key>"',
  fields: ["frontmatter.*"] })`. If one exists, load it and offer to edit rather than recreate — many
  repo notes are also human-written guides, so preserve the body.
- Look for `CONTEXT.md` / `CONTEXT-MAP.md` at the repo root and a `docs/adr/` directory, so you can
  propose sensible `context_path` / `adr_path` values.

### 2. Present findings and decide

Summarise what's present, then walk the user through the decisions **one at a time**. Skip any where
the default is clearly right and just confirm it.

- **Tracker** — `productivity` (default) or `none`. The agent tracks its work as efforts in the vault;
  `none` opts out entirely (rare). There is no external tracker option — the agent never writes to
  Linear/GitHub.
- **External bridge** — `none` (default), `linear`, or `github`. Which external system this repo's
  efforts *correspond to*, so the agent reads context from the right place, links efforts to the
  right tickets, and addresses any drafts correctly. **It does not authorize writing** — Linear/GitHub
  are team communication surfaces the agent only reads and links to. If they pick `linear`, offer to
  record a `linear_team` override (defaults to the vault's `linear_team`).
- **ADR path** — `docs/adr` (default), repo-relative. ADRs stay in the repo (see domain.md).
- **Context path** — `CONTEXT.md` (default). Use `CONTEXT-MAP.md` for multi-context repos.
- **PR surface** — `false` (default). `true` only if external PRs to this repo should be triaged as
  incoming requests.

### 3. Confirm and write

Show the frontmatter you're about to write, let the user edit, then create the note:

```
write_note({
  path: "repos/<slug>.md",
  frontmatter: {
    title: "<owner>/<repo>",
    type: "repo",
    org: "<owner>",
    local_path: "<repo root, ~-abbreviated>",
    remote: "<remote key>",
    tags: ["repo"],
    // tracking fields only when they deviate from defaults:
    // tracker, external_bridge, linear_team, adr_path, context_path, pr_surface
  },
  content: "# <owner>/<repo>\n\n<a short guide: conventions, key paths, gotchas>"
})
```

Pick `<slug>` as `<owner>-<repo>`. Match the existing `repos/` notes' shape (`type: repo`,
`tags: [repo]`, an `org`, a `local_path`, and a human-readable body). Omit tracking fields left at
their default to keep the frontmatter terse — the resolver fills defaults in.

### 4. Done

Tell the user the config is written and which skills now read it (`triage`, `to-spec`, `to-tickets`,
`wayfinder`, `implement`, `domain-modeling`). Note they can edit `repos/<slug>.md` directly later, or
re-run this skill to change trackers.
