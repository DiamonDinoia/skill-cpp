#!/usr/bin/env bash
# Installs the skill from /repo with the mechanism of each harness, then proves each one sees it.
# Runs inside test/Dockerfile. Collects every result and fails at the end.
set -uo pipefail
repo=${1:-/repo}
fail=0
has() { [[ -f $1 ]] && grep -q "$2" "$1"; } # file, pattern
export -f has
check() { # name, command...
  local name=$1; shift
  if out=$("$@" 2>&1); then echo "PASS $name"; else echo "FAIL $name"; echo "$out" | tail -20; fail=1; fi
}

# Every CLI answers its own --version before anything is gated on it.
for c in claude codex gemini opencode; do check "$c --version: $($c --version 2>&1 | head -1)" "$c" --version; done

# Skill format: agentskills.io name rule and the 1024-character description limit.
check "frontmatter name/description" python3 - "$repo/skills/cpp/SKILL.md" <<'EOF'
import re, sys
text = open(sys.argv[1]).read()
fm = text.split("---")[1]
name = re.search(r"^name: (.+)$", fm, re.M).group(1).strip()
desc = re.search(r"^description: (.+)$", fm, re.M).group(1).strip()
assert re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name) and len(name) <= 64 and name == "cpp", name
assert 1 <= len(desc) <= 1024, len(desc)
print(f"name={name} description={len(desc)} chars")
EOF

# Claude Code: plugin marketplace.
check "claude plugin validate --strict" claude plugin validate "$repo" --strict
check "claude marketplace add" claude plugin marketplace add "$repo"
check "claude plugin install" claude plugin install cpp@cpp --scope user
check "claude skill on disk" bash -c 'f=$(find ~/.claude/plugins -path "*skills/cpp/SKILL.md" | head -1); has "$f" "^name: cpp" && echo "$f"'
check "claude plugin list shows cpp" bash -c 'claude plugin list | grep -q "cpp@cpp"'

# Codex: plugin marketplace (reads .claude-plugin/marketplace.json) and the skills directory.
# A fresh CODEX_HOME per run: the control run shares the machine and must not see the main run's cache.
export CODEX_HOME=$(mktemp -d)
check "codex marketplace add" codex plugin marketplace add "$repo"
check "codex marketplace list shows cpp" bash -c 'codex plugin marketplace list | grep -q cpp'
check "codex plugin add" codex plugin add cpp@cpp
check "codex plugin cache has the skill" bash -c 'find "$CODEX_HOME/plugins/cache" -path "*cpp*" -name SKILL.md | grep -q .'
# Codex prefers a native .codex-plugin/plugin.json when present: the cache path carries its version.
# The name assert is the control-run tripwire: CPP_bad must not satisfy it.
check "codex reads .codex-plugin/plugin.json" python3 - "$repo" <<'EOF'
import json, os, re, sys
from pathlib import Path
home = Path(os.environ["CODEX_HOME"])
repo = Path(sys.argv[1])
codex_v = json.loads((repo / ".codex-plugin/plugin.json").read_text())["version"]
claude_v = json.loads((repo / ".claude-plugin/plugin.json").read_text())["version"]
assert codex_v == claude_v, (codex_v, claude_v)  # one release, two manifests
hit = list(home.glob("plugins/cache/*/*/" + codex_v))
assert hit, "codex did not install from the codex manifest version"
skill = hit[0] / "skills/cpp/SKILL.md"
assert skill.exists() and re.search(r"^name: cpp\s*$", skill.read_text(), re.M), skill
print(f"codex native manifest won: {hit[0]}")
EOF

# Gemini CLI: extension.
check "gemini extension install" bash -c "yes | gemini extensions install '$repo' --consent"
check "gemini extensions list shows cpp" bash -c 'gemini extensions list 2>&1 | grep -q cpp'
check "gemini skill on disk" has ~/.gemini/extensions/cpp/skills/cpp/SKILL.md "^name: cpp"

# By hand, as in the README, in a fresh home.
manual=$(mktemp -d)
check "manual symlink" bash -c "mkdir -p '$manual/.claude/skills' && ln -s '$repo/skills/cpp' '$manual/.claude/skills/cpp'"
check "manual skill on disk" has "$manual/.claude/skills/cpp/SKILL.md" "^name: cpp"

(( fail )) && echo "RESULT: FAIL" || echo "RESULT: PASS"
exit $fail
