#!/usr/bin/env python3
"""Validate rendered TOML/YAML/JSON/plist config files for syntax errors.

Walks a chezmoi-rendered destination directory and parses every structured
config file. Exits non-zero if any file fails to parse so CI catches
template-introduced syntax errors before deploy.

Usage:
    validate-configs.py /tmp/chezmoi-dest [--quiet]

Formats handled:
    .toml          → tomllib (stdlib, Python 3.11+)
    .yaml / .yml   → PyYAML safe_load_all (multi-doc OK)
    .json          → json.loads (or JSONC for known editor configs)
    .jsonc         → comment-stripped JSON
    .plist         → plistlib (XML and binary)

Empty files and comment-only files are accepted; the underlying parsers
handle them correctly except for plain JSON, which is treated as empty
when whitespace-only.
"""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import sys
import tomllib
from pathlib import Path

import yaml

# Files that use JSONC (JSON with `//` comments and trailing commas).
# VS Code and Cursor read these as JSONC at runtime.
JSONC_PATH_MARKERS: tuple[str, ...] = (
    "Code/User/settings.json",
    "Code/User/keybindings.json",
    "Cursor/User/settings.json",
    "Cursor/User/keybindings.json",
)

_BLOCK_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)
_TRAILING_COMMA = re.compile(r",(\s*[\]}])")


def is_jsonc(path: Path) -> bool:
    if path.suffix == ".jsonc":
        return True
    s = str(path)
    return any(marker in s for marker in JSONC_PATH_MARKERS)


def strip_jsonc(text: str) -> str:
    """Strip JSONC syntax (`//` line comments, `/* */` blocks, trailing commas).

    Preserves `//` and `/*` that appear inside JSON string literals. Good
    enough for VS Code/Cursor settings; not a full JSONC parser.
    """
    text = _BLOCK_COMMENT.sub("", text)
    out: list[str] = []
    in_string = False
    escape = False
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if escape:
            out.append(c)
            escape = False
            i += 1
            continue
        if in_string:
            if c == "\\":
                out.append(c)
                escape = True
                i += 1
                continue
            if c == '"':
                in_string = False
            out.append(c)
            i += 1
            continue
        if c == '"':
            in_string = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        out.append(c)
        i += 1
    return _TRAILING_COMMA.sub(r"\1", "".join(out))


def validate_toml(path: Path) -> str | None:
    try:
        with path.open("rb") as f:
            tomllib.load(f)
    except Exception as e:
        return f"{type(e).__name__}: {e}"
    return None


def validate_yaml(path: Path) -> str | None:
    try:
        with path.open("r", encoding="utf-8") as f:
            # safe_load_all handles single + multi-document YAML and
            # returns None for empty/comment-only files.
            list(yaml.safe_load_all(f))
    except Exception as e:
        return f"{type(e).__name__}: {e}"
    return None


def validate_json(path: Path, *, jsonc: bool) -> str | None:
    try:
        text = path.read_text(encoding="utf-8")
        if not text.strip():
            return None  # empty file is acceptable
        if jsonc:
            text = strip_jsonc(text)
        json.loads(text)
    except Exception as e:
        return f"{type(e).__name__}: {e}"
    return None


def validate_plist(path: Path) -> str | None:
    try:
        with path.open("rb") as f:
            plistlib.load(f)
    except Exception as e:
        return f"{type(e).__name__}: {e}"
    return None


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate rendered TOML/YAML/JSON/plist config files."
    )
    parser.add_argument(
        "dest",
        type=Path,
        help="Rendered chezmoi destination directory (e.g. /tmp/chezmoi-dest)",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Only print failures and the final summary",
    )
    args = parser.parse_args()

    if not args.dest.is_dir():
        print(f"error: {args.dest} is not a directory", file=sys.stderr)
        return 2

    failures: list[tuple[Path, str, str]] = []
    counts: dict[str, int] = {"toml": 0, "yaml": 0, "json": 0, "jsonc": 0, "plist": 0}

    for path in sorted(args.dest.rglob("*")):
        if not path.is_file():
            continue
        suffix = path.suffix.lower()
        if suffix == ".toml":
            kind, err = "toml", validate_toml(path)
        elif suffix in (".yaml", ".yml"):
            kind, err = "yaml", validate_yaml(path)
        elif suffix in (".json", ".jsonc"):
            jsonc = is_jsonc(path)
            kind = "jsonc" if jsonc else "json"
            err = validate_json(path, jsonc=jsonc)
        elif suffix == ".plist":
            kind, err = "plist", validate_plist(path)
        else:
            continue

        rel = path.relative_to(args.dest)
        counts[kind] += 1
        if err:
            failures.append((rel, kind, err))
            print(f"FAIL ({kind}) {rel}\n  {err}", file=sys.stderr)
        elif not args.quiet:
            print(f"ok ({kind}) {rel}")

    summary = ", ".join(f"{v} {k}" for k, v in counts.items() if v) or "no files"
    print(f"\nValidated: {summary}")
    if failures:
        print(f"FAILED: {len(failures)} file(s)", file=sys.stderr)
        return 1
    print("All structured config files parsed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
