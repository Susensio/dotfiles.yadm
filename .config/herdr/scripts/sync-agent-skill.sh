#!/usr/bin/env bash
set -eu

content="$("$MISE_TOOL_INSTALL_PATH/herdr" --skill)"

for skill_dir in \
  "$HOME/.config/.agents/skills/herdr" \
  "$HOME/.config/.claude/skills/herdr"
do
  mkdir -p "$skill_dir"
  printf '%s\n' "$content" > "$skill_dir/SKILL.md"
done
