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

# tmux-only by design (matches this user's environment). For other terminals,
# fall back to the plugin skill (/revdiff:revdiff), which supports popups in
# zellij/kitty/wezterm/ghostty/iterm2/etc.
if [ -z "${TMUX:-}" ] || ! command -v tmux >/dev/null 2>&1; then
    echo "error: not inside a tmux session — this launcher is tmux-only" >&2
    echo "hint: use the plugin skill /revdiff:revdiff for non-tmux terminals" >&2
    exit 1
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

# run revdiff in a new window, then touch the sentinel when it exits. tmux runs
# this whole string via `/bin/sh -c`, so REVDIFF_CMD (already sq-quoted) plus
# the trailing `; touch <sentinel>` is a single well-formed command line.
FULL_CMD="$REVDIFF_CMD; touch $(sq "$SENTINEL")"
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
