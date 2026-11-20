#!/usr/bin/env python3
"""Keep macOS app preferences (plist domains) in step with TOML files chezmoi manages.

Each app gets one file in the chezmoi source:

    home/dot_local/state/dotfiles/defaults/<app>.toml

    domain = "com.example.app"

    [values]
    "Some.key" = "string"        # managed: apply sets it
    "Other.key" = true
    "List.key" = [300, 600]
    "Blob.key" = { data = "7b7d" }  # raw bytes, hex
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
  chezmoi re-add <target> takes the app's values into the source (plain .toml
                          only: chezmoi never re-adds into a template)

`<app>.toml.tmpl` is rendered with `chezmoi execute-template` first, for values
that differ per machine. A template that renders to nothing means the app isn't
managed on this machine.

Lines are rewritten only where the live value differs, so comments and layout
survive. A managed key the plist lacks shows as `{ unset = true }`, so absent
reads the same on both sides.

Before chezmoi can overwrite them, values the app changed since the last apply
are also copied to ~/.local/state/dotfiles/replaced/defaults/ (one copy per
distinct content), per the repo's replaced-copies convention.

Stdlib only, no tomllib: this runs from a chezmoi hook, possibly on macOS's
Python 3.9 before any newer one is installed. The TOML is limited to the subset
above: one `domain` line, then `[values]` with one entry per line (basic or
literal string, bool, int, float, array of those, `{ data = "<hex>" }`, or
`{ unset = true }`), comments allowed.

Usage: defaults-sync.py snapshot | apply
"""

import datetime
import hashlib
import json
import os
import plistlib
import re
import shutil
import struct
import subprocess
import sys
from pathlib import Path

HOME = Path(os.environ.get("CHEZMOI_DEST_DIR") or Path.home())
STATE = Path(os.environ.get("XDG_STATE_HOME") or HOME / ".local/state")
TARGET_DIR = STATE / "dotfiles/defaults"
APPLIED_DIR = TARGET_DIR / ".applied"  # what `apply` last left in the plist
DESIRED_DIR = TARGET_DIR / ".desired"  # the rendered source, as of the last snapshot
REPLACED_DIR = STATE / "dotfiles/replaced/defaults"
SOURCE_SUBDIR = "dot_local/state/dotfiles/defaults"
RENDERING_ENV = "DEFAULTS_SYNC_RENDERING"  # set while rendering, so the hook doesn't recurse

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
    """Split `value  # comment` into ("value", "  # comment"), quote-aware."""
    quote, i = None, 0
    while i < len(rest):
        c = rest[i]
        if quote == '"' and c == "\\":
            i += 2
            continue
        if quote:
            if c == quote:
                quote = None
        elif c in "\"'":
            quote = c
        elif c == "#":
            break
        i += 1
    value = rest[:i].rstrip()
    return value, rest[len(value):]


def parse_string(text):
    if text.startswith('"') and text.endswith('"') and len(text) >= 2:
        return json.loads(text)  # TOML basic strings share JSON's escapes
    if text.startswith("'") and text.endswith("'") and len(text) >= 2:
        return text[1:-1]  # TOML literal string: no escapes
    raise FormatError(f"bad string: {text}")


def parse_scalar(text):
    if text == "true":
        return True
    if text == "false":
        return False
    if text[:1] in "\"'":
        return parse_string(text)
    if re.fullmatch(r"[+-]?\d+", text):
        return int(text)
    if re.fullmatch(r"[+-]?\d+\.\d+([eE][+-]?\d+)?", text):
        return float(text)
    raise FormatError(f"unsupported value: {text}")


ARRAY_ITEM = re.compile(r"""\s*("(?:[^"\\]|\\.)*"|'[^']*'|[^,\s\]]+)\s*(?:,|$)""")


def parse_value(text):
    text, _ = split_comment(text)
    if re.fullmatch(r"\{\s*unset\s*=\s*true\s*\}", text):
        return UNSET
    if m := re.fullmatch(r'\{\s*data\s*=\s*"([0-9a-fA-F]*)"\s*\}', text):
        return bytes.fromhex(m.group(1))
    if text.startswith("["):
        if not text.endswith("]"):
            raise FormatError(f"arrays must fit on one line: {text}")
        inner, items, pos = text[1:-1].strip(), [], 0
        while pos < len(inner):
            m = ARRAY_ITEM.match(inner, pos)
            if not m or m.end() == pos:
                raise FormatError(f"bad array: {text}")
            items.append(parse_scalar(m.group(1)))
            pos = m.end()
        return items
    return parse_scalar(text)


def format_value(value):
    if value is UNSET:
        return UNSET_TEXT
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bytes):
        return f'{{ data = "{value.hex()}" }}'
    if isinstance(value, list):
        return "[" + ", ".join(format_value(v) for v in value) + "]"
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
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    if type(a) is float and type(b) is float:
        # `defaults write -float` stores 32 bits: 0.1 reads back as
        # 0.10000000149011612. Equal at that precision counts as unchanged.
        return a == b or struct.pack("<f", a) == struct.pack("<f", b)
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


def to_json(v):
    if v is UNSET:
        return None
    if isinstance(v, bytes):
        return {"data": v.hex()}
    return v


def from_json(v):
    if v is None:
        return UNSET
    if isinstance(v, dict) and "data" in v:
        return bytes.fromhex(v["data"])
    return v


def load_applied(name):
    path = APPLIED_DIR / f"{name}.json"
    if not path.exists():
        return None
    return {k: from_json(v) for k, v in json.loads(path.read_text()).items()}


def save_applied(name, values):
    APPLIED_DIR.mkdir(parents=True, exist_ok=True)
    data = {k: to_json(v) for k, v in values.items()}
    (APPLIED_DIR / f"{name}.json").write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def source_files(src):
    """(name, path) for each defaults file in the source: <name>.toml[.tmpl]."""
    for path in sorted((src / SOURCE_SUBDIR).iterdir()):
        if path.name.endswith(".toml.tmpl"):
            yield path.name[: -len(".toml.tmpl")], path
        elif path.name.endswith(".toml"):
            yield path.name[: -len(".toml")], path


def render(path, src):
    if not path.name.endswith(".tmpl"):
        return path.read_text()
    cmd = [os.environ.get("CHEZMOI_EXECUTABLE") or "chezmoi", "--source", str(src)]
    if os.environ.get("CHEZMOI_CONFIG_FILE"):
        cmd += ["--config", os.environ["CHEZMOI_CONFIG_FILE"]]
    r = subprocess.run(cmd + ["execute-template"], stdin=path.open(), capture_output=True,
                       text=True, env={**os.environ, RENDERING_ENV: "1"})
    if r.returncode != 0:
        raise FormatError(f"{path}: template failed: {r.stderr.strip()}")
    return r.stdout


def snapshot():
    if os.environ.get(RENDERING_ENV):
        return
    src = Path(os.environ.get("CHEZMOI_SOURCE_DIR") or HOME / ".local/share/chezmoi/home")
    for name, path in source_files(src):
        text = render(path, src)
        desired = DESIRED_DIR / f"{name}.toml"
        target = TARGET_DIR / f"{name}.toml"
        if not text.strip():  # template says: not on this machine
            desired.unlink(missing_ok=True)
            continue
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

        DESIRED_DIR.mkdir(parents=True, exist_ok=True)
        if not desired.exists() or desired.read_text() != text:
            desired.write_text(text)
        if not target.exists() or target.read_text() != rendered:
            target.write_text(rendered)


def write_args(value):
    if isinstance(value, bool):
        return ["-bool", "true" if value else "false"]
    if isinstance(value, int):
        return ["-int", str(value)]
    if isinstance(value, float):
        return ["-float", repr(value)]
    if isinstance(value, str):
        return ["-string", value]
    if isinstance(value, bytes):
        return ["-data", value.hex()]
    if isinstance(value, list):
        args = ["-array"]
        for item in value:
            if isinstance(item, (list, bytes)):
                raise FormatError("arrays hold strings, numbers and bools only")
            args += write_args(item)
        return args
    raise FormatError(f"can't write {type(value).__name__}")


def apply():
    for target in sorted(TARGET_DIR.glob("*.toml")):
        name = target.stem
        text = target.read_text()
        # Only push what chezmoi actually deployed, i.e. the source as the
        # snapshot at the start of this run rendered it. If the user skipped
        # the overwrite (app-side changes kept) or chezmoi stopped at its
        # prompt, the target still holds the live values: leave the plist
        # alone and don't record them as applied.
        desired = DESIRED_DIR / target.name
        if not desired.exists() or desired.read_text() != text:
            continue
        domain, values = parse(text, target)
        live = live_values(domain, values)
        changed = [k for k, v in values.items() if not same(live[k], v)]
        for key in changed:
            want, have = values[key], live[key]
            # `defaults write` keeps an existing key's type (writing -bool over
            # an integer stores an integer), so clear it first.
            if have is not UNSET:
                subprocess.run(["defaults", "delete", domain, key], check=True, capture_output=True)
            if want is not UNSET:
                subprocess.run(["defaults", "write", domain, key, *write_args(want)], check=True)
            shown = format_value(want)
            print(f"defaults: {domain} {key} = {shown if len(shown) < 80 else shown[:77] + '...'}",
                  file=sys.stderr)
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
