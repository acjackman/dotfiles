#!/bin/sh

# Show the currently running Timing.app timer in sketchybar.
# Uses save report (advanced scripting license) to get the current entry —
# no System Events permission needed.

REPORT_FILE="/tmp/sketchybar_timing_report.json"

osascript 2>/dev/null << 'OSASCRIPT'
tell application "TimingHelper"
  set reportSettings to make new report settings
  set first grouping mode of reportSettings to raw
  set time entries included of reportSettings to true
  set time entry title included of reportSettings to true
  set time entry timespan included of reportSettings to true
  set app usage included of reportSettings to false
  set exportSettings to make new export settings
  set file format of exportSettings to JSON
  set short entries included of exportSettings to true
  set startDate to (current date) - 120
  set endDate to current date
  save report with report settings reportSettings export settings exportSettings to POSIX file "/tmp/sketchybar_timing_report.json" between startDate and endDate
end tell
OSASCRIPT

python3 - << 'PYEOF'
import json, sys, datetime, subprocess, os

report_file = "/tmp/sketchybar_timing_report.json"
name = os.environ.get("NAME", "timing")

def sketchybar(*args):
    subprocess.run(["sketchybar", "--set", name] + list(args))

try:
    with open(report_file) as f:
        entries = json.load(f)
except Exception:
    sketchybar("drawing=off")
    sys.exit(0)

# Only time entries have activityTitle
time_entries = [e for e in entries if e.get("activityTitle") is not None]
if not time_entries:
    sketchybar("drawing=off")
    sys.exit(0)

now = datetime.datetime.now(datetime.timezone.utc)
most_recent = max(time_entries, key=lambda e: e.get("endDate", ""))
end_dt = datetime.datetime.fromisoformat(most_recent["endDate"].replace("Z", "+00:00"))

# Running entries have endDate == the report's query time (within ~15s)
if (now - end_dt).total_seconds() > 15:
    sketchybar("drawing=off")
    sys.exit(0)

title = most_recent.get("activityTitle", "")
project_chain = most_recent.get("project", "")
duration = most_recent.get("duration", "")  # format: h:mm:ss
h, m, s = (int(x) for x in duration.split(":"))
total_minutes = h * 60 + m

project = project_chain.split("▸")[-1].strip()
parts = [p for p in [project, title] if p]
label = " | ".join(parts) + f" ({total_minutes}min)"

# Look up the project color (Timing: #RRGGBBAA → sketchybar: 0xAARRGGBB)
icon_color = "0xffffffff"  # default white
if project_chain:
    color_raw = subprocess.run(
        ["osascript", "-e", f"""
tell application "TimingHelper"
  set queue to root projects as list
  repeat while (count of queue) > 0
    set proj to item 1 of queue
    set queue to rest of queue
    if name chain of proj is "{project_chain}" then return color of proj
    set queue to queue & (every project of proj)
  end repeat
  return ""
end tell"""],
        capture_output=True, text=True
    ).stdout.strip()
    if color_raw and color_raw.startswith("#") and len(color_raw) == 9:
        # #RRGGBBAA → 0xAARRGGBB
        rr, gg, bb, aa = color_raw[1:3], color_raw[3:5], color_raw[5:7], color_raw[7:9]
        icon_color = f"0x{aa}{rr}{gg}{bb}"

sketchybar("drawing=on", "icon=󰔚", f"icon.color={icon_color}", f"label={label}")
PYEOF
