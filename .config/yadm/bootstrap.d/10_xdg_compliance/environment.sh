#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
ASSETS_DIR="${SCRIPT_DIR}/assets"

# /usr/lib/environment.d/* and ~/.config/environment.d/* files get merged and sorted lexicographically,
# Make this system config (sets PATH) lower precedence, so user config can override.
if [[ -f /usr/lib/environment.d/99-environment.conf ]]; then
  sudo mv --verbose /usr/lib/environment.d/99-environment.conf /usr/lib/environment.d/00-environment.conf
  sudo ln -sf /dev/null /usr/lib/environment.d/99-environment.conf
fi

# Clears dynamic D-Bus overrides to restore environment.d precedence.
# This prevents stale env-vars from masking configuration updates after systemctl daemon-reload.
[[ -d /etc/X11/Xsession.d ]] || exit 0

CONFIG_FILES=( /etc/X11/Xsession.d/{00xdg-compliance,96fix-env-precedence} )
for config_file in "${CONFIG_FILES[@]}"; do
  sudo install --mode 644 --compare -D --verbose "${ASSETS_DIR}${config_file}" "${config_file}"
done
