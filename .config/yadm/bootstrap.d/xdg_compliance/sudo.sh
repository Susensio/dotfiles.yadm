#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
ASSETS_DIR="${SCRIPT_DIR}/assets"
CONFIG_FILE="/etc/sudoers.d/disable_admin_file"

sudo install --mode 644 --compare -D --verbose "${ASSETS_DIR}${CONFIG_FILE}" "${CONFIG_FILE}"
