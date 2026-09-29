#!/usr/bin/env bash
# omarchy-theme-set-pi writes its theme into ~/.pi/agent whatever
# PI_CODING_AGENT_DIR says, while omarchy-theme-set-claude and
# omarchy-theme-set-hermes read their agent's variable (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/13693; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch \
  pi-theme-agent-dir.patch \
  /usr/bin/omarchy-theme-set-pi 0

# Patch updates the command, not the theme copied before Pi moved to XDG.
agent_dir=${PI_CODING_AGENT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pi/agent}
source_theme=$HOME/.local/state/omarchy/current/theme/pi.json
if [[ -f $source_theme && -d $agent_dir ]] &&
  ! cmp -s "$source_theme" "$agent_dir/themes/omarchy-system.json"; then
  PI_CODING_AGENT_DIR=$agent_dir omarchy-theme-set-pi
fi
