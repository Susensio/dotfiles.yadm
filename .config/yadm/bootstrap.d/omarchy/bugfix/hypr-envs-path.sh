#!/usr/bin/env bash
# Omarchy's Hyprland envs put $OMARCHY_PATH/bin first on the session PATH, ahead
# of ~/bin/overrides and ADR-0007's ~/.local/bin links (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/13351; delete this step once it ships
set -euo pipefail

OMARCHY_DIR=/usr/share/omarchy
PATCH=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets/hypr-envs-path.patch

[[ -d $OMARCHY_DIR ]] || exit 0

if patch -d "$OMARCHY_DIR" -p1 -R -f -s -F0 --dry-run <"$PATCH" &>/dev/null; then
  exit 0
elif ! patch -d "$OMARCHY_DIR" -p1 -N -f -s -F0 --dry-run <"$PATCH" &>/dev/null; then
  log warn "$(basename "$PATCH") no longer applies to Omarchy: check the PR and drop this step"
else
  sudo patch -d "$OMARCHY_DIR" -p1 -N -f -F0 --no-backup-if-mismatch <"$PATCH"
fi
