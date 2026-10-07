#!/usr/bin/env bash
set -euo pipefail

# herdr's skill mirrors are untracked links into its versioned mise install, so
# a fresh clone or a pull that untracked them leaves none until herdr's own
# postinstall runs; relink only when one is missing or dangling.
command -v mise &>/dev/null || exit 0
install=$(mise where herdr 2>/dev/null) || exit 0
[[ -f $install/SKILL.md ]] || exit 0

config_home=${XDG_CONFIG_HOME:-$HOME/.config}
mirrors=("$config_home/.claude/skills/herdr-config/SKILL.md")
for harness_root in \
  "${CLAUDE_CONFIG_DIR:-$config_home/claude}" \
  "${CODEX_HOME:-$config_home/codex}" \
  "${OPENCODE_CONFIG_DIR:-$config_home/opencode}" \
  "${PI_CODING_AGENT_DIR:-$config_home/pi/agent}"; do
  [[ -d $harness_root ]] && mirrors+=("$harness_root/skills/herdr/SKILL.md")
done

for mirror in "${mirrors[@]}"; do
  [[ -e $mirror ]] && continue
  log info "Relinking herdr skill mirrors"
  # The mise install, not a stale distro herdr that may sit earlier on PATH
  MISE_TOOL_INSTALL_PATH=$install mise run herdr-integrations
  exit 0
done
