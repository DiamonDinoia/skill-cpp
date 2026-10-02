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
out=$("$1" --version 2>&1) || { echo "$1: --version failed" >&2; exit 1; }
ver=$(printf '%s\n' "$out" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
[ -n "$ver" ] || { echo "$1: no version in --version output" >&2; exit 1; }
# Too old iff any of the first three numeric components of $ver is below $2's.
# awk is POSIX; sort -V is a GNU extension.
older=$(awk -v a="$ver" -v b="$2" 'BEGIN {
  n=split(a,x,"."); m=split(b,y,".");
  for (i=1; i<=3; i++) {
    p=(i<=n ? x[i] : 0)+0; q=(i<=m ? y[i] : 0)+0;
    if (p<q) { print 1; exit } else if (p>q) { print 0; exit }
  }
  print 0
}')
[ "$older" = 1 ] && { echo "$1 $ver < $2" >&2; exit 1; }
exit 0
