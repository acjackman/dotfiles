#!/usr/bin/env bash
# safe-rg: read-only rg wrapper
set -euo pipefail

exec rg "$@"
