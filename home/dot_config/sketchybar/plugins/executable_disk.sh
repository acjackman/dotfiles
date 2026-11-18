#!/bin/sh

ICON="󰋊"
GREEN="0xffa6e3a1"
YELLOW="0xfff9e2af"
RED="0xfff38ba8"

VOLUME="${DISK_VOLUME:-/}"

# Use macOS NSURL API to get purgeable-aware disk usage.
# This matches what Finder, Stats, and DaisyDisk report.
PERCENTAGE="$(swift -e '
import Foundation
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
let vals = try url.resourceValues(forKeys: keys)
let total = Double(vals.volumeTotalCapacity!)
let avail = Double(vals.volumeAvailableCapacityForImportantUsage!)
print(Int(100 * (total - avail) / total))
' "$VOLUME" 2>/dev/null)"

# Fallback to df if Swift fails
if [ -z "$PERCENTAGE" ]; then
  PERCENTAGE="$(df -h "$VOLUME" | awk 'NR==2 {print $5}' | tr -d '%')"
fi

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

if [ "$PERCENTAGE" -ge 90 ]; then
  COLOR="$RED"
elif [ "$PERCENTAGE" -ge 80 ]; then
  COLOR="$YELLOW"
else
  COLOR="$GREEN"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
