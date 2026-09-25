#!/usr/bin/env bash
set -euo pipefail

skills_root=${OMARCHY_PATH:-/usr/share/omarchy}/default/agents/skills
[[ -d $skills_root ]] || exit 0

config_home=${XDG_CONFIG_HOME:-$HOME/.config}

declare -A skill_dirs=(
  [claude]="${CLAUDE_CONFIG_DIR:-$config_home/claude}/skills"
  [codex]="${CODEX_HOME:-$config_home/codex}/skills"
  [pi]="${PI_CODING_AGENT_DIR:-$config_home/pi/agent}/skills"
  [opencode]="${OPENCODE_CONFIG_DIR:-$config_home/opencode}/skills"
  [gemini]="${GEMINI_CLI_HOME:-$HOME/.gemini}/skills"
  [hermes]="$HOME/.hermes/skills"
)

for agent in "${!skill_dirs[@]}"; do
  command -v "$agent" &>/dev/null || continue
  destination=${skill_dirs[$agent]}
  mkdir -p "$destination"
  for skill in "$skills_root"/*/; do
    [[ -d $skill ]] || continue
    skill=${skill%/}
    target=$destination/${skill##*/}
    if [[ -e $target && ! -L $target ]]; then
      printf 'Skipping existing skill directory: %s\n' "$target" >&2
      continue
    fi
    ln -sfn "$skill" "$target"
  done
done
