#!/usr/bin/env bash
# Keep Chromium warm and route desktop launches through the user PATH.
set -euo pipefail

command -v chromium &>/dev/null || exit 0

ASSETS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets
APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
# Preserve the packaged launcher and its actions while allowing a PATH override.
if [[ -f /usr/share/applications/chromium.desktop ]]; then
  desktop=$(mktemp)
  trap 'rm -f "$desktop"' EXIT
  sed 's|^Exec=/usr/bin/chromium|Exec=chromium|' /usr/share/applications/chromium.desktop >"$desktop"
  if ! cmp -s "$desktop" "$APPS/chromium.desktop"; then
    install -Dv --mode=644 "$desktop" "$APPS/chromium.desktop"
  fi
fi

UNIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
if ! cmp -s "$ASSETS_DIR/chromium.service" "$UNIT_DIR/chromium.service"; then
  install -Dv --mode=644 "$ASSETS_DIR/chromium.service" "$UNIT_DIR/chromium.service"
  systemctl --user daemon-reload
fi
if ! systemctl --user is-enabled --quiet chromium.service; then
  systemctl --user enable chromium.service
fi
