#!/usr/bin/env bash
# Chromium signs in to Google only with Chrome's OAuth client in its flags, and
# stays running in the background so a new window skips the cold start.
set -euo pipefail

command -v omarchy-install-chromium-google-account &>/dev/null || exit 0

FLAGS=${XDG_CONFIG_HOME:-$HOME/.config}/chromium-flags.conf
if ! grep -q -- --oauth2-client-id "$FLAGS" 2>/dev/null; then
  # The account script only appends to an existing file
  [[ -f $FLAGS ]] || omarchy-refresh-config chromium-flags.conf
  omarchy-install-chromium-google-account
fi

ASSETS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets
UNIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
if ! cmp -s "$ASSETS_DIR/chromium.service" "$UNIT_DIR/chromium.service"; then
  install -Dv --mode=644 "$ASSETS_DIR/chromium.service" "$UNIT_DIR/chromium.service"
  systemctl --user daemon-reload
fi
if ! systemctl --user is-enabled --quiet chromium.service; then
  systemctl --user enable chromium.service
fi
