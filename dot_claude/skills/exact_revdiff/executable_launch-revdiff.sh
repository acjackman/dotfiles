#!/usr/bin/env bash
# launch-revdiff.sh — open revdiff in a NEW tmux window, ASYNC (non-blocking).
#
# Unlike the umputun/revdiff plugin's bundled launcher (which BLOCKS in a tmux
# display-popup until the user quits — and times out the agent's Bash call on
# long reviews), this launcher returns immediately:
#
#   1. opens revdiff in a dedicated tmux window and switches focus to it so the
#      user can start reviewing right away
#   2. the window auto-closes when revdiff exits (remain-on-exit is off by
#      default; we force it off in case the user's tmux config enables it)
#   3. a wrapper touches a SENTINEL file after revdiff exits — the skill arms a
#      Monitor on that sentinel to be re-invoked when the review finishes, then
#      reads the --output file
#
# The agent is freed the whole time the user reviews (typically 10+ min), so no
# blocked Bash call and no timeout.
#
# usage: launch-revdiff.sh [--background] [ref] [against] [--staged] [--only=file] \
#            [--all-files] [--exclude=prefix] [--description=... | --description-file=...]
#
# --background (launcher-only flag, stripped before revdiff sees it): open the
#   review window WITHOUT stealing tmux focus (tmux new-window -d). Use this when
#   a background/spawned agent opens the review — otherwise the new window yanks
#   the user's view away from whatever they're doing. Omit it for the normal case
#   (the user's own session opening a review, where landing in it is desired).
#
# stdout (machine-readable, one field per line — the skill parses these):
#   output_file: <path>   annotations written here on quit (pre-created; empty file = user quit without annotating)
#   sentinel: <path>      touched after revdiff exits — Monitor watches for this to appear
#   window_id: <tmux id>  the revdiff window (diagnostics / manual cleanup)

set -euo pipefail

# Surface selection: open the review in whichever multiplexer is hosting the
# caller (coexistence rule — never cross herdr and tmux). herdr when we're in a
# herdr context and its server is up; tmux otherwise. Both are async and use the
# same sentinel/output-file handshake below; the tmux path additionally requires
# being inside a tmux session (the hard-fail moved into that branch). For other
# terminals, fall back to the plugin skill (/revdiff:revdiff), which supports
# popups in zellij/kitty/wezterm/ghostty/iterm2/etc.
#
# herdr detection uses `herdr pane current` (resolves the caller's own pane by
# controlling TTY) rather than the $HERDR_ENV/$HERDR_SESSION env vars — those
# are plain env vars that must survive every layer of process inheritance
# (Claude's Bash tool, Task-tool subagents, `cat prompt | claude` pipes,
# long-lived sessions predating this adapter) to stay trustworthy. A dropped
# var silently degrades to the tmux branch below, which then blindly trusts
# whatever stale/foreign $TMUX happens to be inherited — attaching a review to
# an unrelated tmux session instead of the caller's actual herdr pane. The TTY
# check is env-independent, so it can't silently go stale the same way.
SURFACE=tmux
if command -v herdr >/dev/null 2>&1 \
    && herdr status server 2>/dev/null | grep -q '^status: running' \
    && herdr pane current >/dev/null 2>&1; then
    SURFACE=herdr
fi

# resolve revdiff to an absolute path so the tmux child shell (whose PATH may
# lack /opt/homebrew/bin) can still find it.
REVDIFF_BIN=$(command -v revdiff 2>/dev/null || true)
if [ -z "$REVDIFF_BIN" ]; then
    echo "error: revdiff not found in PATH" >&2
    echo "install: brew install umputun/apps/revdiff (or https://github.com/umputun/revdiff/releases)" >&2
    exit 1
fi

# pull the launcher-only --background flag out of the args; everything else is
# forwarded to revdiff. reset the positional params so the rest of the script
# (which forwards "$@" to revdiff) never sees --background. the ${NEWARGS[@]+…}
# guard keeps this safe under `set -u` when no revdiff args remain.
BACKGROUND=0
NEWARGS=()
for arg in "$@"; do
    case "$arg" in
        --background) BACKGROUND=1 ;;
        *) NEWARGS+=("$arg") ;;
    esac
done
set -- ${NEWARGS[@]+"${NEWARGS[@]}"}

TMPBASE="${TMPDIR:-/tmp}"
# output file is pre-created so it always exists (empty == no annotations).
OUTPUT_FILE=$(mktemp "$TMPBASE/revdiff-output-XXXXXX")
# sentinel path is reserved but must NOT exist until revdiff exits, so the
# Monitor's `[ -f "$SENTINEL" ]` is a reliable level-triggered completion check.
SENTINEL=$(mktemp "$TMPBASE/revdiff-done-XXXXXX")
rm -f "$SENTINEL"

# shell-quote a single argument for safe embedding in an sh -c string.
sq() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

REVDIFF_CMD="$(sq "$REVDIFF_BIN")"
if [ -n "${REVDIFF_CONFIG:-}" ] && [ -f "$REVDIFF_CONFIG" ]; then
    REVDIFF_CMD="$REVDIFF_CMD $(sq "--config=$REVDIFF_CONFIG")"
fi
REVDIFF_CMD="$REVDIFF_CMD $(sq "--output=$OUTPUT_FILE")"
for arg in "$@"; do
    REVDIFF_CMD="$REVDIFF_CMD $(sq "$arg")"
done

# the tmux server predates the user's shell rc, so EDITOR/VISUAL exports are
# lost in the child. revdiff's multi-line annotation flow (Ctrl+E) hands off to
# $EDITOR, so prepend `env KEY=VAL` to preserve the caller's editor.
ENV_PREFIX=""
for _name in EDITOR VISUAL; do
    if [ "${!_name+x}" = x ]; then
        ENV_PREFIX="$ENV_PREFIX $(sq "${_name}=${!_name}")"
    fi
done
unset _name
if [ -n "$ENV_PREFIX" ]; then
    REVDIFF_CMD="/usr/bin/env$ENV_PREFIX $REVDIFF_CMD"
fi

CWD="$(pwd)"

# descriptive window title: "rd: dirname [ref]"
DIR_NAME=$(basename "$CWD")
TITLE_REF=""
SKIP_NEXT=0
for arg in "$@"; do
    if [ "$SKIP_NEXT" -eq 1 ]; then SKIP_NEXT=0; continue; fi
    case "$arg" in
        -o|--output) SKIP_NEXT=1 ;;
        --output=*) ;;
        -*) ;;
        *) TITLE_REF="$arg"; break ;;
    esac
done
WINDOW_TITLE="rd: ${DIR_NAME}${TITLE_REF:+ [$TITLE_REF]}"

# revdiff plus a sentinel touch is one command line the surface's shell runs;
# when it finishes, the skill's Monitor sees the sentinel file appear. REVDIFF_CMD
# is already sq-quoted, so this is a single well-formed command line.
FULL_CMD="$REVDIFF_CMD; touch $(sq "$SENTINEL")"

if [ "$SURFACE" = herdr ]; then
    # Open the review in a herdr pane split beside the CALLER's pane — not
    # whatever pane happens to be focused. `herdr pane split` with no target
    # splits the focused pane, which silently diverges from the caller when
    # the user's focus has moved elsewhere (e.g. a background/spawned agent,
    # or the user clicked away while the agent was working). Resolve the
    # caller's own pane id via `herdr pane current` (same TTY-based lookup
    # used for surface detection above) and pass it explicitly as the split
    # target so the review always lands beside the invoking agent.
    CALLER_PANE=$(herdr pane current | jq -r '.result.pane.pane_id // empty') \
        || { echo "error: herdr pane current failed" >&2; exit 1; }
    [ -n "$CALLER_PANE" ] || { echo "error: could not resolve caller pane id" >&2; exit 1; }

    # herdr panes host a shell (unlike tmux's command-window), so append
    # `exit` to drop that shell when revdiff quits — the pane then closes
    # cleanly. --background opens it without stealing focus (for a
    # spawned/background agent).
    FOCUS=--focus
    [ "$BACKGROUND" -eq 1 ] && FOCUS=--no-focus
    SPLIT=$(herdr pane split "$CALLER_PANE" --direction right --cwd "$CWD" "$FOCUS") \
        || { echo "error: herdr pane split failed" >&2; exit 1; }
    PANE_ID=$(printf '%s' "$SPLIT" | jq -r '.result.pane.pane_id // empty')
    [ -n "$PANE_ID" ] || { echo "error: could not resolve herdr pane id from split" >&2; exit 1; }
    herdr pane run "$PANE_ID" "$FULL_CMD; exit" >/dev/null \
        || { echo "error: herdr pane run failed" >&2; exit 1; }

    echo "output_file: $OUTPUT_FILE"
    echo "sentinel: $SENTINEL"
    echo "pane_id: $PANE_ID"
    exit 0
fi

# tmux path (default). Requires being inside a tmux session; tmux runs the whole
# FULL_CMD string via `/bin/sh -c`.
if [ -z "${TMUX:-}" ] || ! command -v tmux >/dev/null 2>&1; then
    echo "error: not inside a tmux session — this launcher needs tmux or herdr" >&2
    echo "hint: use the plugin skill /revdiff:revdiff for other terminals" >&2
    exit 1
fi

NEWWIN_ARGS=(new-window -P -F '#{window_id}' -n "$WINDOW_TITLE" -c "$CWD")
# -d opens the window in the background without switching focus to it.
[ "$BACKGROUND" -eq 1 ] && NEWWIN_ARGS+=(-d)
WINDOW_ID=$(tmux "${NEWWIN_ARGS[@]}" "$FULL_CMD")

# belt-and-suspenders: if the user's config sets remain-on-exit on globally, the
# window would linger as "[exited]" after revdiff quits. Force it off for this
# window so it closes cleanly. (The sentinel is touched either way, so Monitor
# still fires even if this races or fails.)
tmux set-window-option -t "$WINDOW_ID" remain-on-exit off >/dev/null 2>&1 || true

echo "output_file: $OUTPUT_FILE"
echo "sentinel: $SENTINEL"
echo "window_id: $WINDOW_ID"
