#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
ASSETS_DIR="${SCRIPT_DIR}/assets"

FILE='/etc/lightdm/lightdm.conf'
CONF='user-authority-in-system-dir'

command -v lightdm &>/dev/null || exit 0

# https://askubuntu.com/questions/960793/whats-the-right-place-to-set-the-xauthority-environment-variable/961459#961459
if [[ -f "${FILE}" ]]; then
  grep -q "^${CONF}=true" "${FILE}" && exit 0
  sudo sed -i -e "/#${CONF}/s/^#//g" -e "/${CONF}/s/=false/=true/g" "${FILE}"
else
  sudo install -Dv --mode 644 "${ASSETS_DIR}${FILE}" "${FILE}"
fi
