# Worktrunk Config

After making changes to files in this directory, run `chezmoi apply` to deploy changes.

The `run_onchange_after_merge-worktrunk-config.py.tmpl` script runs automatically when the script itself changes. It merges chezmoi-managed settings with the machine-local `[projects]` section, preserving local project definitions while updating managed configuration.

## Hooks

`hooks/wt-mux-hook.sh` is wired as both `[pre-remove]` and `[pre-merge]` (as the
`mux` hook). It stops `wt remove`/`wt merge` from deleting a worktree that still
has live work in it: panes sitting in the worktree that run nothing but a shell
are killed, and panes running anything else abort the operation with a pointer to
each one.

It scans **both tmux and herdr**, regardless of which one you invoked it from — a
busy herdr pane must block a `wt remove` run from tmux, and vice versa. This is
deliberately unlike `clank`'s "never cross the streams" backend dispatch (see
`dot_config/herdr/CLAUDE.md`): `clank` picks one substrate to *open* a surface on,
whereas a safety check wants to see everything. Landing the caller on the primary
worktree afterwards *is* per-substrate, since you can't switch a tmux client to a
herdr workspace.

Self-identification is `$TMUX_PANE` / `$HERDR_PANE_ID` — the pane running `wt`
would otherwise read as busy and abort us. Use `$HERDR_PANE_ID`, **not** `herdr
pane current`: the latter resolves by controlling TTY and silently falls back to
the *focused* pane for non-herdr callers, which would skip whichever pane you
happen to be looking at.

The herdr side pins the wire protocol via `$CLANK_HERDR_PROTOCOLS` (shared with
`clank`, so one bump moves both) and warns rather than silently skipping the check
when it can't trust the pane JSON.
