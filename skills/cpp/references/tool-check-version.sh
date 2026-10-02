#!/bin/sh
# The tool check that references/tool-check.md states, as an executable helper.
# The test test/tools-container.sh runs this exact file in a container.
# Usage: tool-check-version.sh <tool> <minimum-version>
# Exit: 0 is OK, 1 is too old or no version, 2 is not found.
set -u
if ! command -v "$1" >/dev/null 2>&1; then
  echo "$1: not found" >&2
  exit 2
fi
ver=$("$1" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
[ -n "$ver" ] || { echo "$1: no version in --version output" >&2; exit 1; }
[ "$(printf '%s\n' "$2" "$ver" | sort -V | head -1)" = "$2" ] || {
  echo "$1 $ver < $2" >&2; exit 1; }
