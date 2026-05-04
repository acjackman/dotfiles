#!/usr/bin/env bash
# Lint rendered shell scripts and chezmoi run scripts.
#
# Walks the rendered destination tree (output of `chezmoi apply --destination`)
# and the chezmoi source tree, and runs ShellCheck against:
#   1. Rendered files with a supported shell shebang (bash/sh/dash/ksh).
#   2. Run scripts (`run_onchange_*`, `run_once_*`, `run_after_*`); templated
#      run scripts are first rendered via `chezmoi execute-template`.
#
# zsh is skipped — ShellCheck does not support the dialect. Templates that
# render to empty content (e.g. a darwin-only block on a linux runner) are
# skipped. Files without a shell shebang are skipped.

set -euo pipefail

RENDERED_DIR="${1:-/tmp/chezmoi-dest}"
SOURCE_DIR="${2:-$PWD}"

failures=0
checked=0

is_shell_shebang() {
	case "$1" in
	'#!/bin/sh' | '#!/bin/sh '* | '#! /bin/sh' | '#! /bin/sh '*) return 0 ;;
	'#!/bin/bash' | '#!/bin/bash '* | '#! /bin/bash' | '#! /bin/bash '*) return 0 ;;
	'#!/bin/dash' | '#!/bin/dash '* | '#! /bin/dash' | '#! /bin/dash '*) return 0 ;;
	'#!/bin/ksh' | '#!/bin/ksh '* | '#! /bin/ksh' | '#! /bin/ksh '*) return 0 ;;
	'#!/usr/bin/env bash'*) return 0 ;;
	'#!/usr/bin/env sh'*) return 0 ;;
	'#!/usr/bin/env dash'*) return 0 ;;
	'#!/usr/bin/env ksh'*) return 0 ;;
	esac
	return 1
}

: "${SHELLCHECK_SEVERITY:=error}"

run_shellcheck_file() {
	local path="$1"
	local label="${2:-$path}"
	checked=$((checked + 1))
	if ! shellcheck \
		--severity="$SHELLCHECK_SEVERITY" \
		--source-path="$SOURCE_DIR" --external-sources "$path"; then
		echo "::error file=${label}::ShellCheck failed"
		failures=$((failures + 1))
	fi
}

first_line() {
	# Reads the first line of a file, suppressing bash's null-byte warning so
	# that binary files (icons, compiled binaries) don't pollute output.
	{ head -n 1 "$1" 2>/dev/null || true; } 2>/dev/null
}

echo "==> Linting rendered shell scripts in $RENDERED_DIR"
if [[ -d "$RENDERED_DIR" ]]; then
	while IFS= read -r -d '' file; do
		# Cheap shebang prefilter avoids reading binary files into a variable.
		[[ "$(head -c 2 "$file" 2>/dev/null)" == '#!' ]] || continue
		first=$(first_line "$file")
		if is_shell_shebang "$first"; then
			run_shellcheck_file "$file"
		fi
	done < <(find "$RENDERED_DIR" -type f -print0)
else
	echo "  (skipped: directory not present)"
fi

echo "==> Linting chezmoi run scripts in $SOURCE_DIR"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cz_args=(--source="$SOURCE_DIR")
if [[ -n "${CHEZMOI_CONFIG_FILE:-}" ]]; then
	cz_args+=(--config="$CHEZMOI_CONFIG_FILE")
fi

while IFS= read -r -d '' src; do
	rel="${src#"$SOURCE_DIR"/}"
	rendered_path="$tmpdir/${rel//\//__}"
	rendered_path="${rendered_path%.tmpl}"

	if [[ "$src" == *.tmpl ]]; then
		if ! chezmoi execute-template "${cz_args[@]}" <"$src" >"$rendered_path"; then
			echo "::error file=${rel}::chezmoi execute-template failed"
			failures=$((failures + 1))
			continue
		fi
	else
		cp "$src" "$rendered_path"
	fi

	# Skip empty renders (e.g. darwin-only blocks on a linux runner).
	if [[ ! -s "$rendered_path" ]]; then
		continue
	fi
	first=$(first_line "$rendered_path")
	if ! is_shell_shebang "$first"; then
		continue
	fi

	run_shellcheck_file "$rendered_path" "$rel"
done < <(
	find "$SOURCE_DIR" \
		\( -name 'run_onchange_*' -o -name 'run_once_*' -o -name 'run_after_*' \) \
		-type f \
		-not -path "$SOURCE_DIR/.git/*" \
		-print0
)

echo
echo "ShellCheck: $checked file(s) checked, $failures failure(s)"
if ((failures > 0)); then
	exit 1
fi
