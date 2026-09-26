#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
ASSETS_DIR="${SCRIPT_DIR}/assets"

### ROOT SPACE

ETC_PROFILE_DIR="/etc/profile.d"
ETC_PROFILE_XDG_FILE="${ETC_PROFILE_DIR}/profile_xdg.sh"

cmp -s "${ASSETS_DIR}${ETC_PROFILE_XDG_FILE}" "${ETC_PROFILE_XDG_FILE}" ||
  sudo install -Dv --mode 644 "${ASSETS_DIR}${ETC_PROFILE_XDG_FILE}" "${ETC_PROFILE_XDG_FILE}"


### USER SPACE

# Now move the actual file
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
OLD_PROFILE="${HOME}/.profile"
NEW_PROFILE="$CONF_DIR/profile"

mkdir --parents -- "${CONF_DIR}"

# Check if file exists first
if [[ -f ${OLD_PROFILE} ]]; then
    if [[ ! -f $NEW_PROFILE ]]; then
        mv --verbose -- "${OLD_PROFILE}" "${NEW_PROFILE}"
    else
        log warn "File ${NEW_PROFILE} already exists. Backing up old profile."
        mv --verbose -- "${OLD_PROFILE}" "${NEW_PROFILE}.bak"
    fi
fi
