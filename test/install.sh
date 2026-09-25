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
for c in claude codex gemini opencode skills gh; do check "$c --version: $($c --version 2>&1 | head -1)" "$c" --version; done

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

# skills CLI: one command for Codex, opencode, Cursor and Copilot directories.
check "npx skills add" skills add "$repo" --skill cpp -g -y -a codex -a opencode -a cursor -a github-copilot
# skills 1.7 writes one copy to ~/.agents/skills: Codex, opencode, Cursor, Copilot read it.
check "skills CLI -> ~/.agents/skills" has ~/.agents/skills/cpp/SKILL.md "^name: cpp"
check "skills ls -g shows cpp" bash -c 'skills ls -g 2>&1 | grep -q cpp'
# `-a '*'` covers the whole agentskills ecosystem: one universal copy plus a symlink per agent
# home (skills 1.7: 56 agent dirs; Eve and PromptScript rightly refuse global installs). --force:
# the universal copy exists already from the 4-agent run above. Cursor/Copilot/opencode read the
# universal copy, so the key-dirs check names symlinked homes only.
check "npx skills add --all agents" skills add --force "$repo" --skill cpp -g -y -a '*'
check "all-agents: universal copy resolves" bash -c \
  'n=$(find -L ~ -mindepth 3 -path "*/skills/cpp/SKILL.md" 2>/dev/null | wc -l); [ "$n" -ge 40 ] && echo "$n agent skill dirs"'
check "all-agents: key harness dirs" bash -c '
  for d in ~/.continue/skills/cpp ~/.codeium/windsurf/skills/cpp ~/.roo/skills/cpp; do
    [ -e "$d/SKILL.md" ] || { echo "missing $d"; exit 1; }
  done'

# gh skill: --from-local installs the checkout. The README form installs OWNER/REPO.
# --force below: the skills-CLI all-agents run above already linked ~/.claude/skills/cpp.
check "gh skill install" gh skill install --force "$repo" cpp --from-local --agent claude-code --scope user
check "gh skill on disk" has ~/.claude/skills/cpp/SKILL.md "^name: cpp"
check "gh skill install opencode" gh skill install "$repo" cpp --from-local --agent opencode --scope user
check "opencode skill on disk" has ~/.config/opencode/skills/cpp/SKILL.md "^name: cpp"
check "gh skill install cursor" gh skill install "$repo" cpp --from-local --agent cursor --scope user
check "cursor skill on disk" has ~/.cursor/skills/cpp/SKILL.md "^name: cpp"
check "gh skill install github-copilot" gh skill install "$repo" cpp --from-local --agent github-copilot --scope user
check "copilot skill on disk" has ~/.copilot/skills/cpp/SKILL.md "^name: cpp"
check "gh skill install universal" gh skill install --force "$repo" cpp --from-local --agent universal --scope user
check "universal copy on disk" has ~/.agents/skills/cpp/SKILL.md "^name: cpp"

# By hand, as in the README, in a fresh home: gh skill already wrote ~/.claude/skills/cpp.
manual=$(mktemp -d)
check "manual symlink" bash -c "mkdir -p '$manual/.claude/skills' && ln -s '$repo/skills/cpp' '$manual/.claude/skills/cpp'"
check "manual skill on disk" has "$manual/.claude/skills/cpp/SKILL.md" "^name: cpp"

(( fail )) && echo "RESULT: FAIL" || echo "RESULT: PASS"
exit $fail
