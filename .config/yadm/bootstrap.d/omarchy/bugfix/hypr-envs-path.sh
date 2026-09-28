#!/usr/bin/env bash
# Omarchy's Hyprland envs put $OMARCHY_PATH/bin first on the session PATH, ahead
# of ~/bin/overrides and ADR-0007's ~/.local/bin links (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/13351; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

# The omarchy package owns default/, so the patch is -p1 relative to it.
apply_omarchy_patch \
  hypr-envs-path.patch \
  /usr/share/omarchy/default/hypr/envs.lua 1
