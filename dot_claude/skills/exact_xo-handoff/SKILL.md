---
name: xo-handoff
description: Hand off an ask to XO asynchronously from a surface that isn't the live XO chat — a doer, a cross-repo clanker, a side Claude session, Adam's phone. Use when you need XO to know something or pick something up but can't reach the XO chat directly.
---

# Handing off to XO asynchronously

XO tracks a fleet and a daily log, but it can only react to what reaches it. If you're a doer, a side session, or otherwise not the live XO chat, you can't just say something to XO — you write a handoff file and XO picks it up on its own schedule (cold-start or mid-session reconcile). **This is fire-and-forget, not instant** — don't wait for XO to respond in this session.

## When to use this

- You're a subagent/clanker spawned by XO (or someone else) and you hit something XO needs to know or decide, but you're not the surface Adam is watching.
- You're a side Claude session (e.g. on Adam's phone) and want to queue a task for XO to pick up later.
- Contrast with **`decide`**: `decide add` is for a *multi-option decision* awaiting Adam's verdict. `xo-handoff add` is for handing XO a *task/ask* to track or act on — no decision loop, no verdict channel back.

## How

Shell out to the `xo-handoff` CLI (chezmoi-managed, on PATH):

```
xo-handoff add "<the ask, one line or short paragraph>" \
  --source <label>   # e.g. phone, or the doer's ticket/label
  [-p high|normal|low]   # default normal
  [-t <effort-or-ticket>]  # associate an effort/Linear ticket if relevant
  [-c "<context>"]         # optional free-form notes body
```

It prints the path of the file it wrote and exits 0. Re-running with an id that already exists (same timestamp+slug) fails cleanly with a nonzero exit — this shouldn't normally happen since ids are timestamp-based.

`--source` defaults to `$XO_HANDOFF_SOURCE` if set, else hostname — always pass an explicit label (`phone`, or your doer's ticket/label) so XO's log entry is legible.

## What happens to it

Your file lands in `~/.local/state/xo/inbox/<id>.md`. XO reconciles this directory on cold-start (and mid-session) — for each new file it logs a `### HH:MM —` entry (source + ask) and opens a tracked task, then moves the file to `~/.local/state/xo/inbox/seen/`. You have no visibility into when that happens from this session; if the ask is urgent, say so via `-p high` and also flag it through whatever synchronous channel you do have.

## Schema (for reference — the CLI is the only writer)

```
---
id: 20260710143022-fix-dns
type: handoff
status: new
created-at: 2026-07-10T14:30:22-07:00
source: phone
queued-by: adam
priority: normal
target: INFRA-4592        # optional
files: []                 # optional
working-dir: /Users/...   # optional
close-surface: my-label   # optional — tells XO to `clank close` this surface after ingest
---
## Ask
<the task/instruction>
## Context
<optional free-form notes>
```

`close-surface` is only emitted when you pass `--safe-to-close` (which ties `source` == the surface label). The `/xo-wrapup` skill sets it: an agent wrapping up its own surface hands its context to XO and marks the surface safe to tear down.

Don't hand-write these files — always go through `xo-handoff add`.
