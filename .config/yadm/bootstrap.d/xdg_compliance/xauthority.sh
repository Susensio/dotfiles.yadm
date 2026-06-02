#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
ASSETS_DIR="${SCRIPT_DIR}/assets"

FILE='/etc/lightdm/lightdm.conf'
CONF='user-authority-in-system-dir'

# https://askubuntu.com/questions/960793/whats-the-right-place-to-set-the-xauthority-environment-variable/961459#961459
if [[ -f "${FILE}" ]]; then
  sudo sed -i -e "/#${CONF}/s/^#//g" -e "/${CONF}/s/=false/=true/g" "${FILE}"
else
  sudo install --mode 644 --compare -D --verbose "${ASSETS_DIR}${FILE}" "${FILE}"
fi
