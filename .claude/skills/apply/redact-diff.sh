#!/usr/bin/env bash
# redact-diff.sh — Strip secret values out of a unified diff before it reaches an
# agent's context. Reads a diff on stdin, writes the redacted diff on stdout.
#
# Two layers, because either alone leaks:
#   1. Declared files (passed as arguments, repo-relative exactly as they appear
#      in the "diff --git a/<path>" header) have every content line withheld and
#      replaced with a count. This is for targets whose source template reads a
#      secret store: the changed content IS the secret, so there is nothing in the
#      body worth showing.
#   2. Every remaining line is scanned for well-known credential shapes, which are
#      replaced in place. This catches files nobody remembered to declare — most
#      importantly a deployed file that holds a secret injected after apply by a
#      separate script, where the source template looks innocent.
set -eo pipefail

awk -v declared="$*" '
function redact(s,   orig, low) {
  orig = s
  gsub(/https:\/\/hooks\.slack\.com\/services\/[A-Za-z0-9_\/-]+/, "<<<REDACTED:slack-webhook>>>", s)
  gsub(/https:\/\/[A-Za-z0-9.-]*discord[A-Za-z0-9.]*\/api\/webhooks\/[A-Za-z0-9_\/-]+/, "<<<REDACTED:discord-webhook>>>", s)
  gsub(/xox[abprse]-[A-Za-z0-9-]+/, "<<<REDACTED:slack-token>>>", s)
  gsub(/(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]+/, "<<<REDACTED:github-token>>>", s)
  gsub(/github_pat_[A-Za-z0-9_]+/, "<<<REDACTED:github-pat>>>", s)
  # Anchored on a non-word char and a length floor: a bare /sk-/ matched inside
  # ordinary prose ("Task-based" -> "Ta" + "sk-based").
  gsub(/(^|[^A-Za-z0-9_])sk-(proj-)?[A-Za-z0-9_-]{20,}/, " <<<REDACTED:api-key>>>", s)
  gsub(/AKIA[0-9A-Z]+/, "<<<REDACTED:aws-key-id>>>", s)
  gsub(/AIza[0-9A-Za-z_-]+/, "<<<REDACTED:google-api-key>>>", s)
  gsub(/hc[a-z]ik_[A-Za-z0-9]+/, "<<<REDACTED:honeycomb-key>>>", s)
  gsub(/x-honeycomb-team=[^,;" ]+/, "x-honeycomb-team=<<<REDACTED>>>", s)
  gsub(/[Bb]earer [A-Za-z0-9._~+\/-]+=*/, "Bearer <<<REDACTED>>>", s)
  gsub(/glpat-[A-Za-z0-9_-]+/, "<<<REDACTED:gitlab-token>>>", s)
  gsub(/(npm_|dop_v1_|doo_v1_|shpat_|SG\.)[A-Za-z0-9_.-]+/, "<<<REDACTED:token>>>", s)
  if (s != orig) return s

  # Nothing matched a known shape. Fall back on the assignment itself: a line that
  # names a credential and assigns something non-empty loses its value. Costs some
  # readability on false positives (a comment mentioning "token"), which is the
  # right trade against leaking an unrecognised key format.
  if (match(s, /[:=][ \t]*["'"'"']?[^ \t"'"'"'}[,]/)) {
    low = tolower(substr(s, 1, RSTART - 1))
    if (low ~ /(api[_-]?key|access[_-]?key|secret|password|passwd|token|webhook|credential|private[_-]?key)/)
      return substr(s, 1, RSTART) "<<<REDACTED:value>>>"
  }

  return s
}

function flush() {
  if (inkey) {
    printf "<<< %d line(s) of private key material withheld (unterminated block) >>>\n", keyheld
    inkey = 0
    keyheld = 0
  }
  if (withheld > 0)
    printf "<<< %d content line(s) withheld: %s is generated from a secret store, so its diff body is the secret itself >>>\n", withheld, curfile
  withheld = 0
}

BEGIN {
  n = split(declared, d, " ")
  for (i = 1; i <= n; i++) if (d[i] != "") secret[d[i]] = 1
}

/^diff --git / {
  flush()
  curfile = $NF
  sub(/^b\//, "", curfile)
  inhunk = 0
  inkey = 0
  print
  next
}

# Hunk headers can carry trailing context text, so they get redacted too.
/^@@/ { inhunk = 1; print redact($0); next }

# Only treat ---/+++ as file headers before the first hunk. Inside a hunk a
# removed line whose content starts with "--" renders identically.
!inhunk && /^(index |--- |\+\+\+ |old mode |new mode |new file mode |deleted file mode |similarity index |rename |Binary )/ { print; next }

{
  if (curfile in secret) { withheld++; next }

  # Key material spans many lines, and every one of them is the secret. The BEGIN
  # marker alone is not enough: withhold the whole armoured block.
  if (inkey) {
    keyheld++
    if ($0 ~ /-----END [A-Z ]*PRIVATE KEY-----/) {
      printf "%s<<< %d line(s) of private key material withheld >>>\n", substr($0, 1, 1), keyheld
      inkey = 0
      keyheld = 0
    }
    next
  }
  if ($0 ~ /-----BEGIN [A-Z ]*PRIVATE KEY-----/) {
    inkey = 1
    keyheld = 1
    next
  }

  print redact($0)
}

END { flush() }
'
