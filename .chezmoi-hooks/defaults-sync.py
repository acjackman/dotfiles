#!/usr/bin/env python3
"""Keep macOS app preferences (plist domains) in step with TOML files chezmoi manages.

Each app gets one file in the chezmoi source:

    home/dot_local/state/dotfiles/defaults/<app>.toml

    domain = "com.example.app"

    [values]
    "Some.key" = "string"        # managed: apply sets it
    "Other.key" = true
    "Old.key" = { unset = true } # managed: apply deletes it

A key that isn't listed is ignored: never read, written or removed. To stop
managing a key, delete its line; to get rid of it, mark it `{ unset = true }`.

That file's target, ~/.local/state/dotfiles/defaults/<app>.toml, is never the
desired state: `snapshot` rewrites it from the live plist before chezmoi reads
anything (hooks.read-source-state.pre). So chezmoi compares desired (source)
against live (target), and:

  chezmoi diff / status   show settings changed in the app, or not yet applied
  chezmoi apply           writes the desired file, then `apply` (run_after) makes
                          the plist match it: `defaults write` for values,
                          `defaults delete` for `{ unset = true }`. A value the
                          app changed since the last apply makes chezmoi ask
                          before overwriting, like any locally edited file.
  chezmoi re-add <target> takes the app's values into the source

Lines are rewritten only where the live value differs, so comments and layout
survive. A managed key the plist lacks shows as `{ unset = true }`, so absent
reads the same on both sides.

Before chezmoi can overwrite them, values the app changed since the last apply
are also copied to ~/.local/state/dotfiles/replaced/defaults/ (one copy per
distinct content), per the repo's replaced-copies convention.

Stdlib only, no tomllib: this runs from a chezmoi hook, possibly on macOS's
Python 3.9 before any newer one is installed. The TOML is limited to the subset
above: one `domain` line, then `[values]` with one entry per line (string,
bool, int, float, or `{ unset = true }`), comments allowed.

Usage: defaults-sync.py snapshot | apply
"""

import datetime
import hashlib
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path(os.environ.get("CHEZMOI_DEST_DIR") or Path.home())
STATE = Path(os.environ.get("XDG_STATE_HOME") or HOME / ".local/state")
TARGET_DIR = STATE / "dotfiles/defaults"
APPLIED_DIR = TARGET_DIR / ".applied"  # what `apply` last left in the plist
REPLACED_DIR = STATE / "dotfiles/replaced/defaults"
SOURCE_SUBDIR = "dot_local/state/dotfiles/defaults"

KEY_LINE = re.compile(r'^(\s*)(?:"((?:[^"\\]|\\.)*)"|([A-Za-z0-9_.-]+))\s*=\s*(.+?)\s*$')
SECTION = re.compile(r"^\s*\[([^\]]+)\]\s*$")
UNSET_TEXT = "{ unset = true }"


class Unset:
    def __repr__(self):
        return UNSET_TEXT


UNSET = Unset()


class FormatError(Exception):
    pass


def split_comment(rest):
    """Split `value  # comment` into ("value", "  # comment")."""
    if rest.startswith('"'):
        m = re.match(r'"(?:[^"\\]|\\.)*"', rest)
        end = m.end() if m else len(rest)
    elif rest.startswith("{"):
        end = rest.find("}") + 1 or len(rest)
    else:
        end = rest.find("#") if "#" in rest else len(rest)
    value, tail = rest[:end].rstrip(), rest[end:]
    if tail.strip() and not tail.lstrip().startswith("#"):
        raise FormatError(f"unexpected text after value: {tail.strip()}")
    return value, rest[len(value):]


def parse_value(text):
    text, _ = split_comment(text)
    if re.fullmatch(r"\{\s*unset\s*=\s*true\s*\}", text):
        return UNSET
    if text == "true":
        return True
    if text == "false":
        return False
    if text.startswith('"'):
        return json.loads(text)  # TOML basic strings share JSON's escapes
    if re.fullmatch(r"[+-]?\d+", text):
        return int(text)
    if re.fullmatch(r"[+-]?\d+\.\d+([eE][+-]?\d+)?", text):
        return float(text)
    raise FormatError(f"unsupported value: {text}")


def format_value(value):
    if value is UNSET:
        return UNSET_TEXT
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    raise FormatError(f"unsupported plist type {type(value).__name__}")


def line_key(m):
    return json.loads(f'"{m.group(2)}"') if m.group(2) is not None else m.group(3)


def parse(text, path):
    """Return (domain, {key: value or UNSET}) from a defaults TOML file."""
    domain, values, section = None, {}, None
    for n, line in enumerate(text.splitlines(), 1):
        if m := SECTION.match(line):
            section = m.group(1).strip()
            continue
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = KEY_LINE.match(line)
        if not m:
            raise FormatError(f"{path}:{n}: not a `key = value` line")
        key = line_key(m)
        try:
            value = parse_value(m.group(4))
        except (FormatError, ValueError) as e:
            raise FormatError(f"{path}:{n}: {e}") from None
        if section is None and key == "domain" and isinstance(value, str):
            domain = value
        elif section == "values":
            values[key] = value
        else:
            raise FormatError(f"{path}:{n}: unexpected key {key!r}")
    if domain is None:
        raise FormatError(f"{path}: missing `domain = \"...\"`")
    return domain, values


def read_plist(domain):
    r = subprocess.run(["defaults", "export", domain, "-"], capture_output=True)
    if r.returncode != 0:
        return {}
    return plistlib.loads(r.stdout)


def same(a, b):
    """Equal and the same plist type. True == 1 in Python, but not in a plist."""
    if a is UNSET or b is UNSET:
        return a is b
    if isinstance(a, bool) or isinstance(b, bool):
        return type(a) is type(b) and a == b
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return type(a) is type(b) and a == b
    return type(a) is type(b) and a == b


def live_values(domain, keys):
    plist = read_plist(domain)
    return {k: plist.get(k, UNSET) for k in keys}


def render_live(text, live):
    """The source text with each managed line showing its live value."""
    out, section = [], None
    for line in text.splitlines():
        if m := SECTION.match(line):
            section = m.group(1).strip()
        elif section == "values" and not line.lstrip().startswith("#") and (m := KEY_LINE.match(line)):
            key = line_key(m)
            if not same(parse_value(m.group(4)), live[key]):
                comment = split_comment(m.group(4))[1]
                line = f"{m.group(1)}{json.dumps(key, ensure_ascii=False)} = {format_value(live[key])}{comment}"
        out.append(line)
    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def backup(name, text):
    sha = hashlib.sha256(text.encode()).hexdigest()[:12]
    if list(REPLACED_DIR.glob(f"{name}.toml.*.{sha}")):
        return
    REPLACED_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    dest = REPLACED_DIR / f"{name}.toml.{stamp}.{sha}"
    dest.write_text(text)
    print(f"defaults: {name} settings changed in the app; saved them to "
          f"{str(dest).replace(str(HOME), '~', 1)}", file=sys.stderr)


def load_applied(name):
    path = APPLIED_DIR / f"{name}.json"
    if not path.exists():
        return None
    return {k: UNSET if v is None else v for k, v in json.loads(path.read_text()).items()}


def save_applied(name, values):
    APPLIED_DIR.mkdir(parents=True, exist_ok=True)
    data = {k: None if v is UNSET else v for k, v in values.items()}
    (APPLIED_DIR / f"{name}.json").write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def snapshot():
    src = Path(os.environ.get("CHEZMOI_SOURCE_DIR") or HOME / ".local/share/chezmoi/home")
    for path in sorted((src / SOURCE_SUBDIR).glob("*.toml")):
        name = path.stem
        text = path.read_text()
        domain, values = parse(text, path)
        live = live_values(domain, values)
        rendered = render_live(text, live)

        # Changed in the app since the last apply? Keep a copy before chezmoi
        # gets the chance to overwrite it. Keys the last apply didn't cover
        # (newly added to the source) aren't app changes.
        applied = load_applied(name)
        if applied is not None and any(
            k in applied and not same(applied[k], v) for k, v in live.items()
        ):
            backup(name, rendered)

        target = TARGET_DIR / f"{name}.toml"
        if not target.exists() or target.read_text() != rendered:
            TARGET_DIR.mkdir(parents=True, exist_ok=True)
            target.write_text(rendered)


def defaults_write(domain, key, value):
    flag = {bool: "-bool", int: "-int", float: "-float", str: "-string"}[type(value)]
    arg = ("true" if value else "false") if isinstance(value, bool) else str(value)
    subprocess.run(["defaults", "write", domain, key, flag, arg], check=True)


def defaults_delete(domain, key):
    subprocess.run(["defaults", "delete", domain, key], check=True, capture_output=True)


def apply():
    src = Path(os.environ.get("CHEZMOI_SOURCE_DIR") or HOME / ".local/share/chezmoi/home")
    for target in sorted(TARGET_DIR.glob("*.toml")):
        name = target.stem
        text = target.read_text()
        source = src / SOURCE_SUBDIR / target.name
        # Only push what chezmoi actually deployed. If the user skipped the
        # overwrite (app-side changes kept) or chezmoi stopped at its prompt,
        # the target still holds the live values: leave the plist alone and
        # don't record them as applied.
        if not source.exists() or source.read_text() != text:
            continue
        domain, values = parse(text, target)
        live = live_values(domain, values)
        changed = [k for k, v in values.items() if not same(live[k], v)]
        for key in changed:
            want, have = values[key], live[key]
            # `defaults write` keeps an existing key's type (writing -bool over
            # an integer stores an integer), so clear it first.
            if have is not UNSET:
                defaults_delete(domain, key)
            if want is not UNSET:
                defaults_write(domain, key, want)
            print(f"defaults: {domain} {key} = {format_value(want)}", file=sys.stderr)
        save_applied(name, values)
        if changed:
            print(f"defaults: {domain}: quit and reopen the app if it doesn't pick these up",
                  file=sys.stderr)


def main():
    if shutil.which("defaults") is None:
        return 0  # not macOS
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        if cmd == "snapshot":
            snapshot()
        elif cmd == "apply":
            apply()
        else:
            print("usage: defaults-sync.py snapshot | apply", file=sys.stderr)
            return 2
    except FormatError as e:
        print(f"defaults-sync: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
