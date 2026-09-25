#!/usr/bin/env bash
# Builds the test image, then runs test/install.sh in fresh containers:
#   1. on this repository: every harness must install and see the skill;
#   2. on a copy whose SKILL.md name is invalid: the run must fail (positive control).
# Usage: test/run.sh [docker|podman]
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
engine=${1:-$(command -v podman >/dev/null && echo podman || echo docker)}
"$engine" --version
"$engine" build -t skill-cpp-test "$root/test"

run() { "$engine" run --rm -v "$1:/repo:ro" -v "$root/test/install.sh:/install.sh:ro" skill-cpp-test bash /install.sh /repo; }

echo "== repository"
run "$root"

echo "== positive control: SKILL.md name 'CPP_bad' must fail"
bad=$(mktemp -d)
trap 'rm -rf "$bad"' EXIT
cp -r "$root/." "$bad/"
chmod -R a+rX "$bad"  # mktemp -d is 0700: the container user must read the copy
sed -i 's/^name: cpp$/name: CPP_bad/' "$bad/skills/cpp/SKILL.md"
if log=$(run "$bad" 2>&1); then echo "$log"; echo "control FAILED: the broken skill passed"; exit 1; fi
echo "$log"
# The failure must come from the name check, not from an unreadable mount.
if ! grep -q '^FAIL frontmatter name/description' <<<"$log" || grep -qiE 'EACCES|permission denied' <<<"$log"; then
  echo "control FAILED: the run failed, but not on the invalid name"; exit 1
fi
echo "control PASSED: the broken skill failed on the name check"
