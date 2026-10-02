#!/usr/bin/env bash
# Builds a podman image from scratch and checks the tool-check rule in this repo
# (skills/cpp/references/tool-check.md) for cppman and clang-tidy. Three cases:
# present and new enough (the version check passes, the lint catches all 3 test
# bugs, cppman prints a page), missing (no executable), too old (a fake script on
# PATH prints an old version and the version check flags it). The version check
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
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
 && . "$HOME/.local/bin/env" 2>/dev/null || export PATH="$HOME/.local/bin:$PATH" \
 && uv tool install 'clang-tidy==22.1.0' \
 && uv tool install 'cppman==0.5.9'
ENV PATH="/home/agent/.local/bin:${PATH}"
WORKDIR /home/agent/proj
EOF

# The version check under test, run inside the container with the repo mounted.
check() { podman run --rm -v "$root/skills/cpp:/skill:ro" "$img" \
  bash /skill/references/tool-check-version.sh "$1" "$2"; }

# Case: present and new enough. The version check passes, the lint catches all 3
# test bugs, cppman prints a page.
echo "== case: present, new enough (clang-tidy 22.1.0, cppman 0.5.9)"
min_ct=$(rg -oP '^\| clang-tidy \| \K[0-9.]+' "$root/skills/cpp/references/tool-check.md")
min_cp=$(rg -oP '^\| cppman \| \K[0-9.]+' "$root/skills/cpp/references/tool-check.md")
check clang-tidy "$min_ct" || { echo "version check rejected the installed clang-tidy"; exit 1; }
check cppman "$min_cp" || { echo "version check rejected the installed cppman"; exit 1; }
out=$(podman run --rm -v "$root/test/files:/files:ro" "$img" bash -c '
set -u
cp /files/bugs.cpp /files/CMakeLists.txt .
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON . >/dev/null
clang-tidy -p build \
  --checks="bugprone-use-after-move,clang-diagnostic-*,cppcoreguidelines-narrowing-conversions" \
  --extra-arg=-Wall \
  bugs.cpp 2>&1 | grep -E "warning:|error:" | grep -oE "\[[a-z-]+\]$" | sort -u
cppman -s cppreference.com >/dev/null 2>&1
cppman "vector" 2>/dev/null | cat | head -40 > /tmp/page || true
wc -l < /tmp/page
')
missing=0
for c in bugprone-use-after-move clang-diagnostic-unused-variable cppcoreguidelines-narrowing-conversions; do
  grep -q "\[$c\]" <<<"$out" || { echo "MISSING lint check: $c"; missing=1; }
done
[ "$(command tail -n 1 <<<"$out")" -ge 5 ] || { echo "cppman printed no page"; missing=1; }
[ "$missing" -eq 0 ] || exit 1
echo "present case PASSED"

# Case: missing. An empty PATH hides the real tools; the check reports not found.
echo "== case: missing"
podman run --rm -v "$root/skills/cpp:/skill:ro" "$img" bash -c '
set -eu
export PATH=/usr/bin:/bin
[ "$(bash /skill/references/tool-check-version.sh clang-tidy 22.1.0 || echo rc=$?)" = "rc=2" ]
[ "$(bash /skill/references/tool-check-version.sh cppman 0.5.9 || echo rc=$?)" = "rc=2" ]
' || { echo "missing case FAILED"; exit 1; }
echo "missing case PASSED"

# Case: too old. Fake tools print an old version; the check exits 1.
echo "== case: too old (fake scripts)"
podman run --rm -v "$root/skills/cpp:/skill:ro" "$img" bash -c '
set -eu
mkdir -p bin
printf "#!/bin/sh\necho clang-tidy version 21.1.0\n" > bin/clang-tidy
printf "#!/bin/sh\necho cppman Ver 0.5.0\n" > bin/cppman
chmod +x bin/*
export PATH="$PWD/bin:/usr/bin:/bin"   # fakes first; user tools hidden
ok=0
bash /skill/references/tool-check-version.sh clang-tidy 22.1.0 || ok=$((ok+1))
bash /skill/references/tool-check-version.sh cppman 0.5.9 || ok=$((ok+1))
[ "$ok" -eq 2 ]
' || { echo "too-old case FAILED"; exit 1; }
echo "too-old case PASSED"

echo "ALL TOOL CHECKS PASSED"
