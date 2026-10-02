#!/usr/bin/env bash
# Builds a podman image from scratch and checks the tool-check rule in this repo
# (skills/cpp/references/tool-check.md) for cppman and clang-tidy. Cases:
# present and new enough (the version check passes, the lint catches all 3 test
# bugs, cppman prints a page), missing (exit 2), and fake tools that print an old
# version, print no version, or print a good version and exit 3 (each exit 1). The version check
# under test is skills/cpp/references/tool-check-version.sh, the helper the skill
# text states; the minimums come from the table in tool-check.md. Needs network.
# test/run.sh does not call this script.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
img=skill-cpp-tools-test

podman build --no-cache -t "$img" -f - <<'EOF'
FROM docker.io/library/ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends \
      curl ca-certificates cmake make g++ python3 python3-pip python3-venv \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m agent
USER agent
WORKDIR /home/agent
RUN curl -fLsS -o /tmp/uv-install.sh https://astral.sh/uv/install.sh \
 && sh /tmp/uv-install.sh \
 && export PATH="/home/agent/.local/bin:$PATH" \
 && uv tool install 'clang-tidy==18.1.1' \
 && uv tool install 'cppman==0.5.9'
ENV PATH="/home/agent/.local/bin:${PATH}"
RUN mkdir -p /home/agent/proj
WORKDIR /home/agent/proj
EOF

# The version check under test, run inside the container with the repo mounted.
check() { podman run --rm -v "$root/skills/cpp:/skill:ro" "$img" \
  bash /skill/references/tool-check-version.sh "$1" "$2"; }

# Case: present and new enough. The version check passes, the lint catches all 3
# test bugs, cppman prints a page.
echo "== case: present, new enough (clang-tidy 18.1.1, cppman 0.5.9)"
min_ct=$(awk -F'|' '/clang-tidy/ {gsub(/[ ]/,"",$3); print $3}' "$root/skills/cpp/references/tool-check.md")
min_cp=$(awk -F'|' '/cppman/     {gsub(/[ ]/,"",$3); print $3}' "$root/skills/cpp/references/tool-check.md")
check clang-tidy "$min_ct" || { echo "version check rejected the installed clang-tidy"; exit 1; }
check cppman "$min_cp" || { echo "version check rejected the installed cppman"; exit 1; }
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
podman run --rm -v "$root/test/files:/files:ro" "$img" bash -c '
set -eu -o pipefail
cp /files/bugs.cpp /files/CMakeLists.txt .
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON . >/dev/null
set +e
clang-tidy -p build \
  --checks="-*,bugprone-use-after-move,clang-diagnostic-*,cppcoreguidelines-narrowing-conversions" \
  --extra-arg=-Wall \
  bugs.cpp > lint.out 2>&1
rc=$?
cppman -s cppreference.com >/dev/null 2>&1
cppman "vector" > page.txt 2>/dev/null
rc2=$?
set -e
echo "CLANG_TIDY_RC=$rc"
if grep -q "error:" lint.out; then echo "HAS_ERROR_LINES"; else echo "NO_ERROR_LINES"; fi
grep -E "warning:" lint.out | grep -oE "\[[a-z-]+\]$" | sort -u
echo "CPPMAN_RC=$rc2"
grep -c push_back page.txt || echo 0
' > "$tmp"
cl_rc=$(command grep -oE '[0-9]+$' <<<"$(command grep '^CLANG_TIDY_RC=' "$tmp")")
cp_rc=$(command grep -oE '[0-9]+$' <<<"$(command grep '^CPPMAN_RC=' "$tmp")")
pback=$(command tail -n 1 "$tmp")
out=$(command grep '^\[' "$tmp")
[ "$cl_rc" = 0 ] || { echo "clang-tidy exit $cl_rc, expected 0"; exit 1; }
command grep -q '^NO_ERROR_LINES$' "$tmp" || { echo "lint has error: lines"; exit 1; }
[ "$cp_rc" = 0 ] || { echo "cppman exit $cp_rc, expected 0"; exit 1; }
[ "$pback" -ge 1 ] || { echo "cppman page has no push_back"; exit 1; }
missing=0
for c in bugprone-use-after-move clang-diagnostic-unused-variable cppcoreguidelines-narrowing-conversions; do
  grep -q "\[$c\]" <<<"$out" || { echo "MISSING lint check: $c"; missing=1; }
done
[ "$missing" -eq 0 ] || exit 1
echo "present case PASSED"

# Case: missing. An empty PATH hides the real tools; the check reports not found.
echo "== case: missing"
podman run --rm -v "$root/skills/cpp:/skill:ro" "$img" bash -c '
set -eu
export PATH=/usr/bin:/bin
[ "$(bash /skill/references/tool-check-version.sh clang-tidy 18.1.1 || echo rc=$?)" = "rc=2" ]
[ "$(bash /skill/references/tool-check-version.sh cppman 0.5.9 || echo rc=$?)" = "rc=2" ]
' || { echo "missing case FAILED"; exit 1; }
echo "missing case PASSED"

# Case: too old, no version, failed probe. Fake tools; the documented exit code is 1.
echo "== case: too old, no version, failed probe (fake scripts)"
podman run --rm -v "$root/skills/cpp:/skill:ro" "$img" bash -c '
set -eu
mkdir -p bin
printf "#!/bin/sh\necho clang-tidy version 17.0.1\n" > bin/clang-tidy
printf "#!/bin/sh\necho cppman Ver 0.5.0\n" > bin/cppman
printf "#!/bin/sh\necho no digits here\n" > bin/nover
printf "#!/bin/sh\necho tool version 99.0.0\nexit 3\n" > bin/broken
chmod +x bin/*
export PATH="$PWD/bin:/usr/bin:/bin"   # fakes first; user tools hidden
rc() { bash /skill/references/tool-check-version.sh "$@" 2>/dev/null && echo 0 || echo $?; }
# Boundary compares, fake tools per case. A lexical comparator fails at least one.
mk() { printf "#!/bin/sh\necho \"tool version %s\"\n" "$1" > "bin/$2"; chmod +x "bin/$2"; }
mk 18.10.0 t1810; mk 19.0.0 t19; mk 18.1 t181
[ "$(rc t1810 18.9.0)" = 0 ]   # 18.10.0 vs 18.9.0: numeric accept, lexical reject
[ "$(rc t19 18.9.9)" = 0 ]     # 19.0.0 vs 18.9.9: numeric accept, lexical reject
[ "$(rc t181 18.1.1)" = 1 ]    # 18.1 vs 18.1.1: reject
[ "$(rc clang-tidy 18.1.1)" = 1 ]
[ "$(rc cppman 0.5.9)" = 1 ]
[ "$(rc nover 1.0)" = 1 ]
[ "$(rc broken 1.0)" = 1 ]
' || { echo "exit-code case FAILED"; exit 1; }
echo "exit-code case PASSED"

echo "ALL TOOL CHECKS PASSED"
