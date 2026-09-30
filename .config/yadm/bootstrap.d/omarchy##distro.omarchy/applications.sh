#!/usr/bin/env bash
# Launcher entries shipped as files, for what the omarchy-*-install helpers
# can't express (Keywords, launch-or-focus), such as btop, which Omarchy hides.
set -euo pipefail

ASSETS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets
APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
for desktop in "$ASSETS_DIR"/applications/*.desktop; do
  target=$APPS/$(basename "$desktop")
  cmp -s "$desktop" "$target" || install -Dv --mode=644 "$desktop" "$target"
done
