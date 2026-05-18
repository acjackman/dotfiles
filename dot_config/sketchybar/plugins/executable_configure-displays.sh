#!/bin/sh

# Restrict the sketchybar bar to currently-attached displays, excluding any
# whose system_profiler marketing name contains a substring in EXCLUDE.
#
# Invoked from sketchybarrc at startup and re-run by a hidden item subscribed
# to `display_change` so the include list stays correct when monitors come
# and go.

python3 - << 'PYEOF'
import json, subprocess, sys

EXCLUDE = ["deskpad", "prompter"]

def system_profiler_displays():
    r = subprocess.run(["system_profiler", "SPDisplaysDataType", "-json"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    try:
        return json.loads(r.stdout).get("SPDisplaysDataType", [{}])[0].get("spdisplays_ndrvs", [])
    except Exception:
        return None

def sketchybar_displays():
    r = subprocess.run(["sketchybar", "--query", "displays"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    try:
        return json.loads(r.stdout)
    except Exception:
        return None

def set_bar(value):
    print(f"setting bar to displays: {value}", file=sys.stderr)
    subprocess.run(["sketchybar", "--bar", f"display={value}"])

nds = system_profiler_displays()
displays = sketchybar_displays()

if nds is None or displays is None:
    set_bar("all")
    sys.exit(0)

exclude_ids = set()
for d in nds:
    name = d.get("_name", "").lower()
    if any(x in name for x in EXCLUDE):
        try:
            exclude_ids.add(int(d.get("_spdisplays_displayID"), 16))
        except Exception:
            pass

include = [str(d.get("arrangement-id"))
           for d in displays
           if d.get("DirectDisplayID") not in exclude_ids]

set_bar(",".join(include) if include else "all")
PYEOF
