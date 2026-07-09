---
name: implement
description: "Implement a piece of work described by an effort (spec or ticket) in the productivity vault, then close it out."
disable-model-invocation: true
---

Implement the work described by the user — an **effort** in the productivity vault (a spec or a
ticket), or whatever they point you at. Read `~/.claude/skills/eng-setup/productivity-tracker.md` for
the tracker operations and `~/.claude/skills/eng-setup/domain.md` for domain docs.

## Process

1. **Load the work.** `read_note` the effort. If the user named a ticket, that's the effort; if they
   named a spec, work the frontier of its child tickets one at a time (query per
   productivity-tracker.md → *Query*), clearing context between tickets. Respect the repo's ADRs and
   glossary while implementing.

2. **Claim it.** Move the effort `planning` → `active` (`update_effort_status`) before you start, so
   parallel sessions don't pick it up.

3. **Build it.** Use `/tdd` where possible, at the pre-agreed seams. Run typechecking regularly,
   single test files regularly, and the full test suite once at the end.

4. **Review.** Once the acceptance criteria are met, run `/code-review` on the diff and address what
   it finds.

5. **Commit** your work to the current branch.

6. **Close out.** Tick the effort's acceptance-criteria checkboxes, append a short `## Log` note (what
   landed, the commit), and move it `active` → `done` (`update_effort_status`). If the effort links to
   an external ticket and you want that updated, the agent **drafts** the status note or comment for
   you to post — it never writes to Linear/GitHub itself (productivity-tracker.md → *External trackers
   are read-only for agents*).
