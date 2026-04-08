#!/bin/sh

# Show the currently running Timing.app timer in sketchybar.
#
# Reads directly from Timing's SQLite database (isRunning=1 row), which is the
# only reliable source for a running timer — the save report API only returns
# completed entries. Uses sqlite3 backup to snapshot the DB safely while
# TimingHelper has it open in WAL mode.

DB="$HOME/Library/Application Support/info.eurocomp.Timing2/SQLite.db"
SNAP="/tmp/sketchybar_timing_snap.db"

python3 - << 'PYEOF'
import sqlite3, os, sys, subprocess, time

db_path = os.path.expanduser(
    "~/Library/Application Support/info.eurocomp.Timing2/SQLite.db"
)
snap_path = "/tmp/sketchybar_timing_snap.db"
name = os.environ.get("NAME", "timing")
GRAY = "0xff6c7086"

def sketchybar(*args):
    subprocess.run(["sketchybar", "--set", name] + list(args))

def show_idle():
    sketchybar("drawing=on", "icon.drawing=off", "label=NO TIMER RUNNING", f"label.color={GRAY}")

# Snapshot the live DB via the sqlite3 backup API (handles WAL correctly)
try:
    src = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    dst = sqlite3.connect(snap_path)
    src.backup(dst)
    src.close()
except Exception:
    show_idle()
    sys.exit(0)

# Query for the running task
try:
    row = dst.execute("""
        SELECT
            ta.title,
            ta.startDate,
            p.title   AS project_leaf,
            p.color   AS color,
            (WITH RECURSIVE anc(id, parentID, title) AS (
                SELECT p2.id, p2.parentID, p2.title FROM Project p2 WHERE p2.id = ta.projectID
                UNION ALL
                SELECT p3.id, p3.parentID, p3.title FROM Project p3 JOIN anc ON p3.id = anc.parentID
             )
             SELECT GROUP_CONCAT(title, ' ▸ ') FROM (SELECT title FROM anc ORDER BY id)
            ) AS project_chain
        FROM TaskActivity ta
        LEFT JOIN Project p ON ta.projectID = p.id
        WHERE ta.isRunning = 1 AND ta.isDeleted = 0
        LIMIT 1
    """).fetchone()
    dst.close()
except Exception:
    show_idle()
    sys.exit(0)

if not row:
    show_idle()
    sys.exit(0)

task_title_raw, start_ts, project_leaf, color_raw, project_chain = row

# Task title: explicit title if set, otherwise the project leaf name
task_title = task_title_raw or project_leaf or ""
if not task_title:
    show_idle()
    sys.exit(0)

# Elapsed time
elapsed_secs = time.time() - (start_ts or 0)
total_minutes = int(elapsed_secs / 60)

# Project display label (leaf of chain, excluding the task title itself when
# the task title IS the project leaf)
project_display = ""
if project_chain and task_title_raw:
    # There's a separate task title, so show the project leaf
    project_display = (project_chain.split(" ▸ ")[-1]).strip()

parts = [p for p in [project_display, task_title] if p]
label = " | ".join(parts)
if total_minutes >= 60:
    label += f" ({total_minutes}min)"

# Color: Timing stores #RRGGBBAA, sketchybar wants 0xAARRGGBB
icon_color = "0xffffffff"
if color_raw and color_raw.startswith("#") and len(color_raw) == 9:
    rr, gg, bb, aa = color_raw[1:3], color_raw[3:5], color_raw[5:7], color_raw[7:9]
    icon_color = f"0x{aa}{rr}{gg}{bb}"

sketchybar("drawing=on", "icon.drawing=on", "icon=󰔚", f"icon.color={icon_color}", f"label={label}", "label.color=0xffffffff")
PYEOF
