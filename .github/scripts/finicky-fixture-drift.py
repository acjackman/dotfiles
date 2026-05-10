#!/usr/bin/env python3
"""Verify a rendered finicky extras.json matches the variant's fixture.

Compares only the keys present in the fixture (machine-derived keys like
meet_app_path live in the rendered file but are intentionally absent from
the fixture).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: finicky-fixture-drift.py <rendered.json> <fixture.json>", file=sys.stderr)
        return 2

    rendered = json.loads(Path(sys.argv[1]).read_text())
    fixture = json.loads(Path(sys.argv[2]).read_text())

    diffs = []
    for key, expected in fixture.items():
        actual = rendered.get(key, "<missing>")
        if actual != expected:
            diffs.append((key, expected, actual))

    if diffs:
        print(f"Fixture drift detected ({len(diffs)} key(s)):", file=sys.stderr)
        for key, expected, actual in diffs:
            print(f"  {key}:", file=sys.stderr)
            print(f"    fixture:  {json.dumps(expected)}", file=sys.stderr)
            print(f"    rendered: {json.dumps(actual)}", file=sys.stderr)
        return 1

    print(f"OK: {len(fixture)} key(s) match between fixture and rendered output.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
