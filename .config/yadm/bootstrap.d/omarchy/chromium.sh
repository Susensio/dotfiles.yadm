#!/usr/bin/env bash
# Keep Chromium running in the background so a new window skips the cold start.
set -euo pipefail

command -v chromium &>/dev/null || exit 0

ASSETS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets
UNIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
if ! cmp -s "$ASSETS_DIR/chromium.service" "$UNIT_DIR/chromium.service"; then
  install -Dv --mode=644 "$ASSETS_DIR/chromium.service" "$UNIT_DIR/chromium.service"
  systemctl --user daemon-reload
fi
if ! systemctl --user is-enabled --quiet chromium.service; then
  systemctl --user enable chromium.service
fi
