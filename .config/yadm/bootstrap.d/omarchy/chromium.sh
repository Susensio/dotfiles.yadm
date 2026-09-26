#!/usr/bin/env bash
# Chromium signs in to Google only with Chrome's OAuth client in its flags
set -euo pipefail

command -v omarchy-install-chromium-google-account &>/dev/null || exit 0

FLAGS=${XDG_CONFIG_HOME:-$HOME/.config}/chromium-flags.conf
if ! grep -q -- --oauth2-client-id "$FLAGS" 2>/dev/null; then
  # The account script only appends to an existing file
  [[ -f $FLAGS ]] || omarchy-refresh-config chromium-flags.conf
  omarchy-install-chromium-google-account
fi
