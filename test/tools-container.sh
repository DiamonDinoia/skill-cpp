#!/usr/bin/env bash
# Builds podman images from scratch and checks the tool-check rule in this repo
# (skills/cpp/references/tool-check.md) for cppman and clang-tidy. Three cases per
# tool: present and new enough (the lint catches all 3 test bugs, cppman prints a
# page), missing (no executable), too old (a fake script on PATH prints an old
# version and the version check, run as the skill text states it, flags it).
# Needs network. test/run.sh does not call this script.
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

# Case: present and new enough. The lint must catch all 3 test bugs and cppman must
# print a page.
echo "== case: present, new enough (clang-tidy 22.1.0, cppman 0.5.9)"
out=$(podman run --rm -v "$root/test/files:/files:ro" "$img" bash -c '
set -u
cp /files/bugs.cpp /files/CMakeLists.txt .
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_FLAGS="-Wall" . >/dev/null
clang-tidy -p build \
  --checks="bugprone-use-after-move,clang-diagnostic-*,cppcoreguidelines-narrowing-conversions" \
  bugs.cpp 2>&1 | grep -E "warning:|error:" | grep -oE "\[[a-z-]+\]$" | sort -u > /tmp/found
cat /tmp/found
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

# Case: missing. An empty PATH hides the real tools; `command -v`, the first step of
# the tool check, must report both tools as missing.
echo "== case: missing"
out=$(podman run --rm "$img" bash -c '
export PATH=/usr/bin:/bin
command -v clang-tidy || echo NO-CLANG-TIDY
command -v cppman || echo NO-CPPMAN
')
grep -q NO-CLANG-TIDY <<<"$out" && grep -q NO-CPPMAN <<<"$out" || { echo "missing case FAILED: $out"; exit 1; }
echo "missing case PASSED"

# Case: too old. A fake tool prints an old version; the version check from the skill
# text, run as written, exits 1.
echo "== case: too old (fake scripts)"
podman run --rm -v "$root/skills/cpp/references:/refs:ro" "$img" bash -c '
set -eu
mkdir -p bin
printf "#!/bin/sh\necho clang-tidy version 21.1.0\n" > bin/clang-tidy
printf "#!/bin/sh\necho cppman 0.5.0\n" > bin/cppman
chmod +x bin/*
export PATH="$PWD/bin:/usr/bin:/bin"   # fakes first; user tools hidden
for spec in "clang-tidy 22.1.0" "cppman 0.5.9"; do
  tool=${spec% *}; min=${spec#* }
  # The version check exactly as references/tool-check.md states it:
  ver=$("$tool" --version | grep -oE "[0-9]+\.[0-9]+(\.[0-9]+)?" | head -1)
  if [ "$(printf "%s\n" "$min" "$ver" | sort -V | head -1)" = "$min" ]; then
    echo "TOO-OLD CHECK FAILED: $tool $ver passed against $min"; exit 1
  fi
  echo "TOO-OLD CHECK OK: $tool $ver < $min"
done
' | { grep -c "TOO-OLD CHECK OK" | grep -qx 2 || { echo "too-old case FAILED"; exit 1; }; echo "too-old case PASSED"; }

echo "ALL TOOL CHECKS PASSED"
