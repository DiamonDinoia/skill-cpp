#!/usr/bin/env bash
# Symlink the cpp skill and its /cpp command shim into opencode. Writes only
# opencode's own directories: the plugin-marketplace harnesses get the skill
# without this script (no duplicate installs).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p ~/.config/opencode/skills ~/.config/opencode/commands

ln -sfn "$ROOT/skills/cpp" ~/.config/opencode/skills/cpp
ln -sfn "$ROOT/.opencode/command/cpp.md" ~/.config/opencode/commands/cpp.md

echo "linked; restart opencode to pick the skill up"
