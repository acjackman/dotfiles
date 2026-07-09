---
name: to-spec
description: Turn the current conversation into a spec and publish it as an effort in the productivity vault — no interview, just synthesis of what you've already discussed.
disable-model-invocation: true
---

This skill takes the current conversation context and codebase understanding and produces a spec
(you may know this document as a PRD). Do NOT interview the user — just synthesize what you already
know.

Work is tracked as **efforts in the productivity vault**. Read
`~/.claude/skills/eng-setup/productivity-tracker.md` for the tracker operations and to resolve this
repo's config, and `~/.claude/skills/eng-setup/domain.md` for the domain-doc rules. If the repo's
`tracker` is an external one, follow that instead — but efforts are the default.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use the
   project's domain glossary vocabulary throughout the spec, and respect any ADRs in the repo's
   `docs/adr/` (see domain.md).

2. Sketch out the seams at which you're going to test the feature. Existing seams should be preferred
   to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest
   point you can. The fewer seams across the codebase, the better — the ideal number is one.

   Check with the user that these seams match their expectations.

3. Write the spec using the template below, then **publish it as an effort**:
   - `create_effort({ title: "<feature name>", goal: "<the Solution, in one or two lines>",
     status: "planning", priority: <if known> })` — this returns the effort path.
   - Append the full spec into the effort body with `effort_append_section` — one call per `##`
     section of the template (Problem Statement, Solution, User Stories, …).
   - Tag it `ready-for-agent` in frontmatter (`update_frontmatter`, `tags: ["ready-for-agent"]`) —
     this spec is agent-grabbable, no further triage needed.

   Do **not** create anything in an external tracker — Linear/GitHub are team communication surfaces
   the agent never writes to. If you want a Linear ticket or GitHub issue for this spec, the agent can
   **draft** the body for you to post yourself, then link the effort to the ticket you create (see
   productivity-tracker.md → *External trackers are read-only for agents*).

<spec-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can
(state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly
that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the
important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.

</spec-template>
