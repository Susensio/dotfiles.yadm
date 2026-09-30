#!/usr/bin/env bash
# Omarchy's Hyprland envs put $OMARCHY_PATH/bin first on the session PATH, ahead
# of ~/bin/overrides and ADR-0007's ~/.local/bin links (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/13351; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

# The omarchy package owns default/, so the patch is -p1 relative to it.
target=/usr/share/omarchy/default/hypr/envs.lua
patch_file=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/patches/hypr-envs-path.patch
needs_patch=false
if patch -p1 -N -f -s -F0 --dry-run "$target" < "$patch_file" &>/dev/null; then
  needs_patch=true
fi
apply_omarchy_patch hypr-envs-path.patch "$target" 1

if $needs_patch && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  omarchy-restart-hyprctl
fi
