#!/usr/bin/env python3
"""Validate rendered Python files and chezmoi Python run scripts.

Walks the chezmoi-rendered destination directory for Python files and
also renders every chezmoi run script template (which aren't deployed
as files) so we can lint them too. Each Python file is checked with:

    1. py_compile.compile (syntax check via stdlib)
    2. ruff check (when --ruff is passed and ruff is on PATH)

A file is considered Python if its name ends in ``.py`` or its first
line is a shebang containing ``python``. Templates that render to empty
content (e.g. a darwin-only block on a linux runner) are skipped.

Usage:
    pycheck-rendered.py <rendered-dir> <source-dir> [--ruff] [--quiet]
"""

from __future__ import annotations

import argparse
import os
import py_compile
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# chezmoi run-script prefixes; covers run_once_*, run_onchange_*, run_after_*.
RUN_SCRIPT_PREFIXES: tuple[str, ...] = (
    "run_once_",
    "run_onchange_",
    "run_after_",
)


def first_line(path: Path) -> str:
    """Return the first line of ``path`` if it starts with a shebang, else ""."""
    try:
        with path.open("rb") as f:
            head = f.read(256)
    except OSError:
        return ""
    if not head.startswith(b"#!"):
        return ""
    line, _, _ = head.partition(b"\n")
    return line.decode("utf-8", errors="replace")


def is_python_file(path: Path) -> bool:
    if path.suffix == ".py":
        return True
    return "python" in first_line(path)


def find_run_scripts(source: Path) -> list[Path]:
    """Return chezmoi run-script source files (templated or not) under ``source``.

    Skips ``.git`` to avoid touching git internals.
    """
    git_dir = source / ".git"
    out: list[Path] = []
    for path in source.rglob("*"):
        if not path.is_file():
            continue
        try:
            path.relative_to(git_dir)
            continue
        except ValueError:
            pass
        if any(path.name.startswith(p) for p in RUN_SCRIPT_PREFIXES):
            out.append(path)
    return sorted(out)


def render_template(src: Path, dst: Path, source_dir: Path) -> tuple[bool, str]:
    """Render ``src`` via ``chezmoi execute-template`` into ``dst``.

    Returns (ok, stderr-text). ``CHEZMOI_CONFIG_FILE`` is honored if set so
    the same config used by the surrounding ``chezmoi apply`` step is reused.
    """
    cmd = ["chezmoi", "execute-template", f"--source={source_dir}"]
    config_file = os.environ.get("CHEZMOI_CONFIG_FILE")
    if config_file:
        cmd.append(f"--config={config_file}")
    with src.open("rb") as src_f, dst.open("wb") as dst_f:
        result = subprocess.run(
            cmd, stdin=src_f, stdout=dst_f, stderr=subprocess.PIPE, check=False
        )
    return result.returncode == 0, result.stderr.decode("utf-8", errors="replace")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Syntax-check rendered Python files and chezmoi run scripts."
    )
    parser.add_argument(
        "rendered_dir",
        type=Path,
        help="Rendered chezmoi destination directory (e.g. /tmp/chezmoi-dest)",
    )
    parser.add_argument(
        "source_dir",
        type=Path,
        help="Chezmoi source directory (the repo root)",
    )
    parser.add_argument(
        "--ruff",
        action="store_true",
        help="Also run `ruff check` on every collected file",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Only print failures and the final summary",
    )
    args = parser.parse_args()

    if not args.source_dir.is_dir():
        print(f"error: {args.source_dir} is not a directory", file=sys.stderr)
        return 2

    failures: list[tuple[str, str]] = []  # (label, error)
    # (on-disk-path, human-label) — label is what we surface in errors and
    # prefer to be a path the user can locate (rendered dest path or source
    # path). The on-disk path is what py_compile / ruff actually read.
    files: list[tuple[Path, str]] = []

    # 1) Rendered Python files under the destination directory.
    if args.rendered_dir.is_dir():
        for path in sorted(args.rendered_dir.rglob("*")):
            if path.is_file() and is_python_file(path):
                files.append((path, str(path.relative_to(args.rendered_dir))))
    else:
        print(f"==> Skipping {args.rendered_dir} (not present)")

    # 2) Chezmoi run scripts — render templates individually so we can lint
    #    files that aren't deployed verbatim.
    tmpdir = Path(tempfile.mkdtemp(prefix="pycheck-"))
    try:
        for src in find_run_scripts(args.source_dir):
            rel = src.relative_to(args.source_dir)
            # Flat tmp filename preserves traceability in tool output.
            rendered_name = str(rel).replace(os.sep, "__")
            if rendered_name.endswith(".tmpl"):
                rendered_name = rendered_name[: -len(".tmpl")]
            rendered = tmpdir / rendered_name

            if src.suffix == ".tmpl":
                ok, err = render_template(src, rendered, args.source_dir)
                if not ok:
                    label = str(rel)
                    msg = err.strip() or "chezmoi execute-template failed"
                    failures.append((label, msg))
                    print(
                        f"::error file={label}::chezmoi execute-template failed: {msg}",
                        file=sys.stderr,
                    )
                    continue
            else:
                shutil.copy(src, rendered)

            try:
                if rendered.stat().st_size == 0:
                    continue
            except FileNotFoundError:
                continue

            if is_python_file(rendered):
                files.append((rendered, str(rel)))

        # py_compile every file we collected.
        print(f"==> py_compile: {len(files)} file(s)")
        py_failures = 0
        for path, label in files:
            try:
                py_compile.compile(str(path), doraise=True)
            except py_compile.PyCompileError as e:
                # PyCompileError messages include the file path of the temp
                # rendered file; replace with the friendly label.
                msg = str(e.msg).strip().replace(str(path), label)
                first_msg_line = msg.splitlines()[-1] if msg else "compile failed"
                failures.append((label, first_msg_line))
                py_failures += 1
                print(
                    f"::error file={label}::py_compile failed\n{msg}",
                    file=sys.stderr,
                )
            else:
                if not args.quiet:
                    print(f"  ok {label}")
        if py_failures == 0:
            print(f"  py_compile: all {len(files)} file(s) ok")

        # ruff (optional) — basic style/lint pass with default rules.
        if args.ruff and files:
            ruff = shutil.which("ruff")
            if not ruff:
                print(
                    "::error::--ruff specified but `ruff` is not on PATH",
                    file=sys.stderr,
                )
                return 2
            print(f"==> ruff check: {len(files)} file(s)")
            cmd = [
                ruff,
                "check",
                "--no-cache",
                "--output-format=github",
                *(str(p) for p, _ in files),
            ]
            result = subprocess.run(cmd, check=False)
            if result.returncode != 0:
                failures.append(("(ruff)", "ruff check reported issues"))
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

    print()
    print(f"Python check: {len(files)} file(s) checked, {len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
