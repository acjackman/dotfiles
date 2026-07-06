---
name: revdiff
description: Review diffs, files, and documents with inline annotations in a revdiff TUI opened in a new tmux window (async — the agent stays free while you review), then capture annotations and address them. Works in git, hg, and jj repos (auto-detected). Activates on "revdiff", "review diff", "review changes", "annotate diff", "review with revdiff", "review jj change", "interactive diff review", "revdiff all files", "review all files", "revdiff <file>", "review this file", "annotate this file", "open this review in revdiff", "review in revdiff". For deep revdiff config/theme/keybinding questions, defer to the plugin skill (revdiff:revdiff) or `revdiff --help`.
---

# revdiff — async TUI diff review (new multiplexer surface)

Review diffs with inline annotations using the revdiff TUI, opened in a **new
surface** (a herdr pane when herdr is the active multiplexer, otherwise a tmux
window) instead of a blocking popup. Works in git, hg, and jj repos (auto-detected).

**Why this exists (vs. the bundled `revdiff:revdiff` plugin skill):** the plugin
launches revdiff in a tmux `display-popup` and **blocks the agent's Bash call**
until you quit. Long reviews (10+ min) blow past the Bash-tool timeout. This skill
opens revdiff in its own surface and returns immediately, then uses a
**Monitor** to be re-invoked when you finish — so the agent is free the whole time
and there is no timeout. This skill shadows the plugin at the `/revdiff` name; the
plugin remains available as `/revdiff:revdiff` (e.g. for other terminals).

The launcher picks the surface by the caller's context (the substrate adapter's
coexistence rule): inside herdr it splits a herdr pane; inside tmux it opens a
tmux window. Either way the async handshake (`output_file` + `sentinel` + Monitor)
is identical, so the steps below are backend-agnostic.

## How it works

1. Detect the ref/mode (Step 1) and launch revdiff in a new surface (Step 2).
   The launcher **returns immediately** with an `output_file` and a `sentinel` path.
2. Arm a **Monitor** on the sentinel (Step 3). Tell the user revdiff is open. The
   agent is now free — do other requested work, or just wait.
3. You review in the new surface, add annotations, and quit (`q`). The surface
   auto-closes; the sentinel appears; Monitor fires and re-invokes the agent.
4. Read `output_file`, classify + address annotations (Steps 4–6), then loop:
   re-launch to verify. Done when you quit with no annotations.

## Scripts

- `~/.claude/skills/revdiff/detect-ref.sh` — smart ref detection (VCS auto-detect)
- `~/.claude/skills/revdiff/launch-revdiff.sh` — async launcher (herdr pane / tmux window)

## Answering questions (don't launch the TUI)

If the user asks *about* revdiff (config file, themes, keybindings, flags) rather
than requesting a review, answer directly — run `revdiff --help`, point at the
config file (`~/.config/revdiff/config` / `--config`), or consult the bundled
plugin's references at
`~/.claude/plugins/marketplaces/revdiff/.claude-plugin/skills/revdiff/references/`
(`config.md`, `usage.md`, `install.md`). Do NOT open the TUI for informational Qs.

## Workflow

### Step 0: Verify installation

```bash
which revdiff
```

If missing: `brew install umputun/apps/revdiff` (or the GitHub releases page).

### Step 1: Determine review mode

**All-files mode** — if `$ARGUMENTS` matches "all files" / "browse all files"
(optionally "exclude <prefix>"): pass `--all-files`, plus `--exclude=<prefix>` per
excluded prefix. Skip ref detection, go to Step 2.

**File review mode** — if `$ARGUMENTS` is a single token pointing at a file (e.g.
`docs/plan.md`, `/tmp/notes.txt`, `README.md`, `main.go`): decide with
`test -f "$ARGUMENTS"`; also treat as file review if it starts with `/` or `./`,
or contains `/` and has an extension. Go to Step 2 with `--only=<filepath>` (no
ref). Works inside or outside a repo (context-only view). Ambiguous bare token
like `main` (branch or filename) → prefer ref mode; only ask if neither
`test -f` nor `git rev-parse --verify` resolves.

**Ref mode** — if `$ARGUMENTS` has explicit ref(s) (`HEAD~1`, `main`, or
`main feature` for a two-ref diff): use as-is.

**Auto-detect** — if no ref given, run:

```bash
~/.claude/skills/revdiff/detect-ref.sh
```

Fields: `branch`, `main_branch`, `is_main`, `has_uncommitted`, `has_staged_only`,
`suggested_ref` (empty = uncommitted), `use_staged`, `needs_ask`.

- `use_staged: true` → pass `--staged` to the launcher (all changes are staged;
  without it revdiff shows an empty diff).
- `needs_ask: true` (feature branch + uncommitted) → ask via AskUserQuestion:
  "Uncommitted only" (no ref) vs "Branch vs {main_branch}" (pass `main_branch`).
- `needs_ask: false` → use `suggested_ref` directly (empty / `HEAD~1` /
  `main_branch` / `--all-files`).

### Step 2: Launch (async)

If you're auto-opening a review after your own work, pass `--description="..."`
(markdown, shown in the `i` info popup) — for longer prose write a temp file and
pass `--description-file=/tmp/revdiff-desc-XXXXXX.md`. The two are mutually
exclusive; both optional; skip when there's no useful context.

Run the launcher. It returns **immediately** (do NOT set a long Bash timeout, and
do NOT background it — it's already non-blocking):

```bash
~/.claude/skills/revdiff/launch-revdiff.sh [--background] [ref] [against] [--staged] [--only=file] [--all-files] [--exclude=prefix] [--description=text|--description-file=path]
```

By default the review surface **takes focus** so the user lands in it to
review — correct for a foreground session. Pass **`--background`** only when *you*
are a background or spawned agent (the user is working elsewhere and shouldn't
have their view yanked to the review); it opens the surface without stealing
focus (`tmux new-window -d`, or a herdr `--no-focus` split). When unsure, omit it.

Capture the fields it prints (the third is `window_id:` on tmux or `pane_id:` on
herdr — diagnostic only; the first two are load-bearing):

```
output_file: /path/to/revdiff-output-XXXXXX
sentinel:    /path/to/revdiff-done-XXXXXX
window_id:   @N          # or  pane_id: wN:pM  on herdr
```

If it errors with "not inside a tmux session" (and herdr isn't active either),
fall back to `/revdiff:revdiff`.

### Step 3: Arm the Monitor and free up

Start a **Monitor** on the sentinel — it emits one line and exits when revdiff
closes, giving you a single wake-up (substitute the real `sentinel` path):

- **command**: `until [ -f "<SENTINEL>" ]; do sleep 1; done; echo "revdiff review finished"`
- **description**: `revdiff review window (<dir> <ref>)`
- **timeout_ms**: `3600000` (60 min — the max; covers long review sessions)
- **persistent**: `false`

Then tell the user: *"revdiff is open in a new window — annotate and press `q`
to finish (`Q` to discard). I'll pick up your annotations automatically when you're
done, and I'm free to keep working meanwhile."* End your turn or continue other
work; the Monitor notification will re-invoke you.

**Fallback** — if the Monitor times out (review > 60 min) or its notification is
missed, the annotations are still on disk: read `output_file` directly, and note
revdiff also auto-saves annotated sessions to `~/.config/revdiff/history/<repo>/`.

### Step 4: On the Monitor notification — collect annotations

When the Monitor fires, read the captured `output_file`:

```bash
cat "<OUTPUT_FILE>"
```

- **Empty** → the user quit without annotating → review complete (Step 7).
- **Has content** → proceed. Clean up the temp files once read:
  `rm -f "<OUTPUT_FILE>" "<SENTINEL>"`.

Output format:

```
## handler.go (file-level)
consider splitting this file

## handler.go:43 (+)
use errors.Is() instead of direct comparison

## handler.go:43-67 (+)
refactor this hunk to reduce nesting

## store.go:18 (-)
don't remove this validation
```

Each block: `## filename:line[-end] (type)` — `(+)` added, `(-)` removed,
`( )` context/unchanged line, `(file-level)` file note; `-end` present for a line
range. Comment text follows. Classification (Step 4.5) keys off the comment text,
not the type, so all types flow through the same way.

### Step 4.5: Classify annotations

Split into two buckets (case-insensitive):

**Explanation requests** — text contains two+ consecutive `?` (`??`, `???`), OR
starts with `explain`, `remind`, `describe`, `what is`, `what are`, `how does`,
`how do`, `clarify`. These want answers, not code changes.

**Code-change directives** — everything else.

**If explanation requests exist**, enter the explanation loop:
1. Answer each (read the referenced code, write clear markdown).
2. Note any code-change directives in the same batch as pending (carry to Step 5).
3. Write the explanation to `/tmp/revdiff-explain-XXXXXX.md` and re-launch (Step 2)
   with `--only=/tmp/revdiff-explain-XXXXXX.md`; arm the Monitor again (Step 3).
   - **User quits without annotating** → explanation accepted; clean up temp file;
     if pending directives exist → Step 5, else re-launch the original diff (Step 6).
   - **User annotates the explanation** → treat as follow-up questions; refine the
     markdown, rewrite the temp file, re-launch. Repeat until they quit clean.

**If no explanation requests** → straight to Step 5.

### Step 5: Plan the changes

Enter plan mode (EnterPlanMode) for the code-change annotations: list each with its
file/line, describe the planned change, get approval before editing.

### Step 6: Address, then loop

After approval, fix the source (each annotation is a directive). Then re-launch
(Step 2) with the same ref and re-arm the Monitor (Step 3) so the user can verify:

- Adds more annotations → back to Step 4.
- Quits with no annotations → complete.

### Step 7: Done

When `output_file` is empty on a pass, the review is complete. Tell the user.

## Opening an in-session review / existing history

- **In-session review** (comments already produced earlier in the conversation):
  write them to `/tmp/revdiff-review-XXXXXX.md` in the output format above, then run
  Step 2 with `--annotations=<temp-path>` appended; Step 4 onward handles them.
- **"Use my latest revdiff annotations"** (user ran revdiff elsewhere): read the
  newest `.md` under `${REVDIFF_HISTORY_DIR:-~/.config/revdiff/history}/<repo>/`
  and process it through Step 4.5.
