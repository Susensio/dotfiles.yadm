#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
ASSETS_DIR="${SCRIPT_DIR}/assets"
CONFIG_FILE="/etc/sudoers.d/disable_admin_file"

# Only Debian's sudo writes ~/.sudo_as_admin_successful
command -v apt-get &>/dev/null || exit 0

# sudoers.d is root-only, so only existence can be checked without sudo
[[ -e $CONFIG_FILE ]] && exit 0
sudo install --mode 440 -D "${ASSETS_DIR}${CONFIG_FILE}" "${CONFIG_FILE}"
log info "Installed ${CONFIG_FILE}"
