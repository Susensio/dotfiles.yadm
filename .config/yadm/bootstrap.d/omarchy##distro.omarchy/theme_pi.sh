#!/usr/bin/env bash
# omarchy-theme-set copies the rendered theme into pi's agent root, which the
# patch in bugfix/pi-theme-agent-dir.sh makes PI_CODING_AGENT_DIR-aware.
# Bug fixes sort before the steps that render, so that step ran before the
# render it had to copy and left the agent's copy a run stale; this runs after
# theme.sh and copies only when it differs, so a rerun writes nothing (ADR-0111).
set -euo pipefail

command -v omarchy-theme-set-pi &>/dev/null || exit 0

agent_dir=${PI_CODING_AGENT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pi/agent}
source_theme=${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current/theme/pi.json
[[ -f $source_theme && -d $agent_dir ]] || exit 0
cmp -s "$source_theme" "$agent_dir/themes/omarchy-system.json" && exit 0

log info "Copying the Omarchy theme into pi's agent root..."
PI_CODING_AGENT_DIR=$agent_dir omarchy-theme-set-pi
