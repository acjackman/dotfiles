# Documentation Guide

How the agent documentation in this repository is structured and how to maintain it.

## Structure

```
CLAUDE.md              → Root entry point, references AGENTS.md
AGENTS.md              → Focused overview with pointers to .docs/
.docs/                 → Detailed topic docs (not deployed by chezmoi)
  chezmoi.md           → Chezmoi workflow, file mapping, special files, commands
  code-style.md        → Shell, Python, Lua, template conventions
  git-workflows.md     → Bare repos, worktrees, worktrunk
  docs-guide.md        → This file
**/CLAUDE.md           → Directory-specific instructions (auto-loaded by agents)
```

## Design Principles

- **AGENTS.md stays focused.** It's the project overview — enough context to orient an agent, with references to `.docs/` for detail.
- **`.docs/` holds cross-cutting detail.** Topics that span multiple directories or aren't tied to a specific config tool.
- **Subdirectory `CLAUDE.md` files stay co-located.** They auto-load when agents work in that directory and contain only directory-specific instructions (reload commands, script descriptions, tool-specific notes).
- **Agents load docs on demand.** AGENTS.md references `.docs/` files but does not `@`-include them, keeping the default context small.

## When to Update

| Change | Where to update |
|---|---|
| New config tool added | Add a `CLAUDE.md` in its directory |
| New cross-cutting convention | Add to or create a `.docs/` file, reference from AGENTS.md |
| Chezmoi workflow change | `.docs/chezmoi.md` |
| Code style change | `.docs/code-style.md` |
| Git/worktree workflow change | `.docs/git-workflows.md` |
| AGENTS.md too long | Extract detail into `.docs/`, replace with reference |

## File Format

- Use standard Markdown
- Keep files focused on one topic
- Start with a `# Title` heading
- No `@` includes in `.docs/` files — they are leaf documents

## Chezmoi Handling

The `.docs/` directory is automatically ignored by chezmoi because it starts with a literal `.` in the source directory (chezmoi only maps `dot_` prefixed entries to `.`). No `.chezmoiignore` entry is needed.

Similarly, `AGENTS.md` and `**/CLAUDE.md` are listed in `.chezmoiignore` to prevent deployment.
