#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
ASSETS_DIR="${SCRIPT_DIR}/assets"

source "${HOME}/bin/log"

### ROOT SPACE

ETC_BASHRC_FILE="/etc/bash.bashrc"
ETC_BASHRC_DIR="/etc/bashrc.d"
ETC_BASHRC_XDG_FILE="${ETC_BASHRC_DIR}/xdg.sh"
ETC_PROFILE_DIR="/etc/profile.d"
ETC_PROFILE_XDG_FILE="${ETC_PROFILE_DIR}/bash_xdg.sh"

if ! grep --quiet "${ETC_BASHRC_DIR}" ${ETC_BASHRC_FILE}; then
  log_info "Patching /etc/bash.bashrc to support /etc/bashrc.d/*..."
  cat "${ASSETS_DIR}${ETC_BASHRC_FILE}.patch" | sudo tee --append ${ETC_BASHRC_FILE} > /dev/null
else
  log_debug "/etc/bash.bashrc is already patched. Skipping."
fi

# Install the asset files directly into /etc
sudo install --mode 644 --compare -D --verbose "${ASSETS_DIR}${ETC_BASHRC_XDG_FILE}" "${ETC_BASHRC_XDG_FILE}"
sudo install --mode 644 --compare -D --verbose "${ASSETS_DIR}${ETC_PROFILE_XDG_FILE}" "${ETC_PROFILE_XDG_FILE}"


### USER SPACE

# Now move the actual files
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bash"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash"
HIST_FILE="${HOME}/.bash_history"
BASH_DOTFILES="${HOME}/.bash*"

mkdir --parents -- "${CONF_DIR}" "${DATA_DIR}"

# First move .bash_history, it goes to different folder
if [[ -f ${HIST_FILE} ]]; then
  mv --verbose -- "${HIST_FILE}" "${DATA_DIR}/history"
fi

# Now the remaining .bash* files
# Check if glob gives results
if compgen -G "${BASH_DOTFILES}" > /dev/null; then
  for file in ${BASH_DOTFILES}; do
    base=$(basename "${file}")
    # Update possible references to ~/.bash_aliases in .bashrc
    if [[ ${base} == ".bashrc" ]]; then
      sed --in-place "s|~/.bash_aliases|${CONF_DIR}/bash_aliases|g" "${file}"
    fi
    # remove dot with :1
    dest="${CONF_DIR}/${base:1}"

    if [[ ! -f $dest ]]; then
      mv --verbose -- "${file}" "${dest}"
    else
      mv --verbose -- "${file}" "${dest}.bak"
      log_warn "File ${dest} already exists. Renamed to ${dest}.bak"
    fi

  done
fi
