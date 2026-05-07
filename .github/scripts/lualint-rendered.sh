#!/usr/bin/env bash
# Lint rendered Lua files and chezmoi Lua templates.
#
# Walks the rendered destination tree (output of `chezmoi apply --destination`)
# and the chezmoi source tree, and runs:
#   1. `luac -p` syntax check on every rendered `.lua` file.
#   2. For every `.lua.tmpl` source file: render via `chezmoi execute-template`
#      and run `luac -p` on the rendered output.
#   3. `stylua --check` on each rendered subtree that contains a `stylua.toml`.
#
# Templates that render to empty content (e.g. a darwin-only block on a linux
# runner) are skipped. StyLua is skipped if not installed; syntax check is the
# hard requirement.

set -euo pipefail

RENDERED_DIR="${1:-/tmp/chezmoi-dest}"
SOURCE_DIR="${2:-$PWD}"

# Pick a luac binary. Prefer plain `luac` (whatever the OS provides), fall
# back to versioned binaries that Debian/Ubuntu ships under explicit names.
LUAC="${LUAC:-}"
if [[ -z "$LUAC" ]]; then
	for cand in luac luac5.4 luac5.3 luac5.1; do
		if command -v "$cand" >/dev/null 2>&1; then
			LUAC="$cand"
			break
		fi
	done
fi
if [[ -z "$LUAC" ]]; then
	echo "::error::no luac binary found on PATH (tried luac, luac5.4, luac5.3, luac5.1)"
	exit 2
fi

syntax_failures=0
syntax_checked=0

run_luac() {
	local path="$1"
	local label="${2:-$path}"
	syntax_checked=$((syntax_checked + 1))
	local out
	if ! out=$("$LUAC" -p "$path" 2>&1); then
		echo "::error file=${label}::luac -p failed"
		# Rewrite the temp path back to the friendly label so users can locate
		# the source file from the error output.
		printf '%s\n' "$out" | sed "s|$path|$label|g"
		syntax_failures=$((syntax_failures + 1))
	fi
}

echo "==> Syntax-checking rendered .lua files in $RENDERED_DIR (using $LUAC)"
if [[ -d "$RENDERED_DIR" ]]; then
	while IFS= read -r -d '' file; do
		run_luac "$file" "${file#"$RENDERED_DIR"/}"
	done < <(find "$RENDERED_DIR" -type f -name '*.lua' -print0)
else
	echo "  (skipped: directory not present)"
fi

echo "==> Rendering and syntax-checking .lua.tmpl source files in $SOURCE_DIR"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cz_args=(--source="$SOURCE_DIR")
if [[ -n "${CHEZMOI_CONFIG_FILE:-}" ]]; then
	cz_args+=(--config="$CHEZMOI_CONFIG_FILE")
fi

while IFS= read -r -d '' src; do
	rel="${src#"$SOURCE_DIR"/}"
	# Flat tmp filename keeps traceability in tool output; drop .tmpl so
	# the rendered file has a `.lua` extension that stylua/luac recognize.
	rendered_path="$tmpdir/${rel//\//__}"
	rendered_path="${rendered_path%.tmpl}"

	if ! chezmoi execute-template "${cz_args[@]}" <"$src" >"$rendered_path"; then
		echo "::error file=${rel}::chezmoi execute-template failed"
		syntax_failures=$((syntax_failures + 1))
		continue
	fi

	# Skip empty renders (e.g. an OS-only block on a different runner).
	if [[ ! -s "$rendered_path" ]]; then
		continue
	fi

	run_luac "$rendered_path" "$rel"
done < <(
	find "$SOURCE_DIR" -name '*.lua.tmpl' -type f \
		-not -path "$SOURCE_DIR/.git/*" \
		-not -path "$SOURCE_DIR/.worktrees/*" \
		-print0
)

# StyLua format check — runs once per rendered subtree that ships a
# `stylua.toml`. This lets each tool (nvim, hammerspoon, ...) carry its own
# style without forcing repo-wide rules.
stylua_failures=0
stylua_checked=0
echo "==> StyLua format check (rendered subtrees with stylua.toml)"
if ! command -v stylua >/dev/null 2>&1; then
	echo "  (skipped: stylua not installed)"
elif [[ -d "$RENDERED_DIR" ]]; then
	while IFS= read -r -d '' cfg; do
		dir=$(dirname "$cfg")
		rel="${dir#"$RENDERED_DIR"/}"
		echo "  checking $rel/"
		stylua_checked=$((stylua_checked + 1))
		if ! stylua --check "$dir"; then
			echo "::error file=${rel}::stylua --check failed"
			stylua_failures=$((stylua_failures + 1))
		fi
	done < <(find "$RENDERED_DIR" -type f -name 'stylua.toml' -print0)
	if ((stylua_checked == 0)); then
		echo "  (no stylua.toml found in rendered tree)"
	fi
else
	echo "  (skipped: rendered directory not present)"
fi

echo
echo "Lua syntax ($LUAC -p): $syntax_checked file(s) checked, $syntax_failures failure(s)"
echo "StyLua format check: $stylua_checked subtree(s) checked, $stylua_failures failure(s)"

if ((syntax_failures > 0 || stylua_failures > 0)); then
	exit 1
fi
