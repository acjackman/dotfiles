#!/usr/bin/env python3
"""Generate a Dash cheat sheet docset from a YAML definition."""
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///

import argparse
import html
import plistlib
import sqlite3
from pathlib import Path
from urllib.parse import quote

import yaml


def generate_html(data: dict) -> str:
    title = data["title"]
    intro = data.get("introduction", "")
    categories = data.get("categories", [])

    rows = []
    for cat in categories:
        cat_id = cat["id"]
        cat_id_escaped = quote(cat_id, safe="")

        rows.append(
            f'<section class="category">\n'
            f'<h2 id="//dash_ref/Category/{cat_id_escaped}/1">{html.escape(cat_id)}</h2>\n'
            f'<div class="scrollable"><table>'
        )

        for entry in cat.get("entries", []):
            name = entry.get("name", "")
            commands = entry.get("commands", [])
            if isinstance(commands, str):
                commands = [commands]
            notes = entry.get("notes", "")
            name_escaped = quote(name, safe="")

            anchor = f"//dash_ref_{cat_id_escaped}/Entry/{name_escaped}/0"
            rows.append(f'<tr id="{anchor}">')

            if commands:
                cmd_html = "".join(
                    f"<p><code>{html.escape(c)}</code></p>" for c in commands
                )
                rows.append(f'<td class="command">{cmd_html}</td>')

            desc = f'<div class="name">{html.escape(name)}</div>'
            if notes:
                desc += f'<div class="notes">{html.escape(notes)}</div>'
            colspan = ' colspan="2"' if not commands else ""
            rows.append(f'<td class="description"{colspan}>{desc}</td>')
            rows.append("</tr>")

        rows.append("</table></div></section>")

    body = "\n".join(rows)
    intro_html = f"<p>{html.escape(intro)}</p>" if intro else ""

    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>{html.escape(title)}</title>
<link href="style.css" rel="stylesheet">
</head>
<body>
<header><h1>{html.escape(title)}</h1></header>
<article>
{intro_html}
{body}
</article>
</body>
</html>"""


def generate_index(data: dict, db_path: Path) -> None:
    db_path.unlink(missing_ok=True)
    conn = sqlite3.connect(db_path)
    conn.execute(
        "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT)"
    )

    idx = 1
    for cat in data.get("categories", []):
        cat_id = cat["id"]
        cat_id_escaped = quote(cat_id, safe="")
        conn.execute(
            "INSERT INTO searchIndex VALUES (?, ?, ?, ?)",
            (idx, cat_id, "Category", f"index.html#//dash_ref/Category/{cat_id_escaped}/1"),
        )
        idx += 1

        for entry in cat.get("entries", []):
            name = entry.get("name", "")
            name_escaped = quote(name, safe="")
            anchor = f"index.html#//dash_ref_{cat_id_escaped}/Entry/{name_escaped}/0"

            commands = entry.get("commands", [])
            if isinstance(commands, str):
                commands = [commands]
            for cmd in commands:
                conn.execute(
                    "INSERT INTO searchIndex VALUES (?, ?, ?, ?)",
                    (idx, cmd, "Command", anchor),
                )
                idx += 1

            conn.execute(
                "INSERT INTO searchIndex VALUES (?, ?, ?, ?)",
                (idx, name, "Entry", anchor),
            )
            idx += 1

    conn.commit()
    conn.close()


def generate_plist(data: dict, plist_path: Path) -> None:
    plist = {
        "CFBundleIdentifier": "cheatsheet",
        "CFBundleName": data["title"],
        "DashDocSetFamily": "cheatsheet",
        "DashDocSetKeyword": data.get("keyword", ""),
        "DashDocSetPluginKeyword": data.get("keyword", ""),
        "DocSetPlatformFamily": "cheatsheet",
        "dashIndexFilePath": "index.html",
        "isDashDocset": True,
    }
    with open(plist_path, "wb") as f:
        plistlib.dump(plist, f)


# Minimal CSS (based on cheatset's default, without bundled fonts)
STYLE_CSS = """\
h1, h2, h3, p, blockquote { margin: 0; padding: 0; }
body { font-family: -apple-system, 'Helvetica Neue', sans-serif; font-size: 16px; color: #000; background-color: #fff; margin: 0; }
code, pre { font-family: Menlo, Consolas, monospace; font-size: 15px; }
code { margin: 0; border: 1px solid #ddd; background-color: #f8f8f8; border-radius: 3px; white-space: nowrap; }
code:before, code:after { content: "\\00a0"; }
header { color: #efefef; background-color: #666; padding: 0px 10px 3px 10px; }
h1 { font-size: 35px; font-weight: 600; }
article { margin: 2em 1em; }
section.category { border: 2px solid #666; border-radius: 6px; background-color: #666; margin: 2em 0; overflow: hidden; padding-bottom: 5px; }
section.category h2 { color: #fff; font-size: 1.5em; text-align: center; margin-top: -2px; font-weight: 600; }
table { background-color: #fff; border-collapse: collapse; width: 100%; }
td { padding: 13px 8px 0px 8px; border-left: 1px solid #d7d7d7; }
tr { border-bottom: 1px dotted #d7d7d7; }
tr:last-child { border-bottom: none; }
td.command { width: 1%; white-space: nowrap; vertical-align: top; padding: 9px 8px 4px 7px; text-align: right; }
td.command code { padding: .1em 0.2em; box-shadow: 0 1px 0px rgba(0,0,0,0.2), 0 0 0 2px #fff inset; border-radius: 3px; border: 1px solid #ccc; background-color: #efefef; color: #333; }
td.description .name { font-size: 1.2em; margin-top: -4px; }
.scrollable { overflow-x: auto; }
p { margin: 0 0 7px; }
"""


def main():
    parser = argparse.ArgumentParser(description="Generate a Dash cheat sheet docset")
    parser.add_argument("source", help="YAML source file")
    parser.add_argument("-o", "--output", help="Output directory (default: current dir)")
    args = parser.parse_args()

    source = Path(args.source)
    with open(source) as f:
        data = yaml.safe_load(f)

    docset_name = data.get("docset_file_name", data["title"].replace(" ", "_"))
    out_dir = Path(args.output) if args.output else source.parent
    docset_dir = out_dir / f"{docset_name}.docset"

    docs_dir = docset_dir / "Contents" / "Resources" / "Documents"
    docs_dir.mkdir(parents=True, exist_ok=True)

    generate_plist(data, docset_dir / "Contents" / "Info.plist")
    generate_index(data, docset_dir / "Contents" / "Resources" / "docSet.dsidx")

    (docs_dir / "index.html").write_text(generate_html(data))
    (docs_dir / "style.css").write_text(STYLE_CSS)

    print(f"Generated {docset_dir}")


if __name__ == "__main__":
    main()
