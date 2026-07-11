---
name: xo-wrapup
description: Wrap up a work surface and hand its full context back to XO. Invoked INSIDE a doer / side session — either Adam types `/xo-wrapup` when a piece of work is done, or an agent self-invokes at the end of its task. Introspects the session (decisions, git/PR state, open threads), synthesizes an XO-ready handoff, and — if everything material is captured — marks the surface safe for XO to tear down. Use when a surface's work is finished (or paused) and XO should pick up from here.
user-invocable: true
---

# Wrapping up a surface for XO

You are inside a **work surface** — a clank doer, a cross-repo clanker, or a side Claude session — not the live XO chat. This skill hands your surface's *full context* back to XO so it can update its ledger, track the open threads, and (when safe) tear this surface down. It's the natural bookend to `xo-handoff`: same channel (`xo-handoff add` → the XO inbox), but the payload is a **wrap-up of everything this session did and left open**, plus an explicit safe-to-close signal.

**This is fire-and-forget.** You write the handoff and report to Adam; XO ingests it on its own schedule (cold-start or mid-session reconcile). Do **not** wait for XO in this session, and do **not** close your own surface (see step 5).

## When to use this

- An agent finishes (or pauses) the task it was spawned for and wants XO to take over the follow-up — self-invoke as the last step.
- Adam types `/xo-wrapup` in a doer because the work there is done and he wants it folded back into XO's picture.
- Contrast with plain `xo-handoff`: that hands XO *one new ask* from a surface. `/xo-wrapup` hands XO *this surface's whole story* — what was done, what's still open — and offers the surface up for teardown.

## Steps

### 1. Introspect the session

Gather everything XO needs to reconstruct this thread. Pull from the conversation **and** the environment — don't rely on memory alone:

- **Decisions / findings** — what was decided, discovered, or ruled out in this conversation.
- **Repo state** — `git status`, `git diff --stat`, and the current branch (`git branch --show-current`).
- **PR / CI** — if a PR exists: `gh pr view` and `gh pr checks` (PR number, red/green).
- **Location** — cwd / worktree (`pwd`).
- **The effort / ticket** — from the branch name, the spawn brief, or the conversation. This becomes `-t <effort-or-ticket>`.
- **The surface label** — discover it agent-agnostically:
  1. `herdr pane current` → read `.result.pane.workspace_id` (e.g. `w1S`).
  2. Match that `workspace_id` in `clank list` → the entry's `label` is your surface label. (Equivalently `herdr workspace get <workspace_id>` → `.result.workspace.label`.)
  3. If `herdr`/`clank` isn't available or returns nothing, **ask Adam** for the label — do not guess, and do not pass `--safe-to-close` without a verified label (a wrong label would close the wrong surface).

### 2. Synthesize the XO-ready handoff

Compose two parts:

- **`## Ask`** (one line) — what XO should *do next* with this thread. E.g. "Track INFRA-4592 review — PR up, CI green, awaiting Adam's approval to merge" or "Pick up the DNS follow-up; root cause found, fix not yet started."
- **`## Context`** (the body) — capture the **open threads explicitly**, not a dated recap. Include:
  - unresolved questions and pending decisions,
  - follow-ups and the next concrete step,
  - latent bugs / risks discovered,
  - artifact state: PR number, branch, CI red/green, whether pushed/merged.

  This is durable open-threads capture — the point is that nothing material dies with this surface. Write it so XO (and Adam, weeks later) can pick up cold.

### 3. Confidence gate

Decide whether **everything material is captured** in the handoff.

- **CONFIDENT** → the Context fully captures the state; nothing important lives only in this session's scrollback. Include `--safe-to-close`.
- **UNCERTAIN** → something material may be uncaptured (a half-finished investigation, unpushed work you're not sure about, a thread you can't fully summarize). Do **not** pass `--safe-to-close`. Instead, list what's unresolved both in the `## Context` body and in your reply to Adam, and leave the surface open so the work can be resumed here.

State the verdict either way in your reply.

### 4. Write it back (fire-and-forget)

Shell out to the `xo-handoff` CLI. When confident, `--source` **must** be the verified surface label (it ties `source` == label — that's the surface XO will close):

```
xo-handoff add "<the one-line ask>" \
  -c "<the ## Context body>" \
  --source <surface-label> \
  [-t <effort-or-ticket>] \
  [-p high|normal|low] \
  [--file <path> ...] \
  [--safe-to-close]        # only when the confidence gate passed
```

It prints the path of the file it wrote and exits 0. **Echo that path** in your reply. Do not wait for XO to respond.

### 5. No self-close — report to Adam

**Never call `clank close` on your own surface.** Closing the surface you're running in mid-turn kills you before you can report; teardown is XO's job on its next reconcile (it verifies the `close-surface:` label is live and not `XO`, then closes it). Your job ends at the handoff.

Report to Adam:

- **Gate passed:** "Wrapped and handed to XO (`<path>`). Marked safe-to-close — XO tears this surface down on its next reconcile. If you want it gone now, close it yourself."
- **Gate failed:** "Wrapped and handed to XO (`<path>`). Left the surface open — unresolved: `<list what's uncaptured / needs resume>`."
