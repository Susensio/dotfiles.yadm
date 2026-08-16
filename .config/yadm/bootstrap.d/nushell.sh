#!/usr/bin/env bash
set -euo pipefail

source "${HOME}/bin/log"

if [[ "$(cat /etc/os-release | grep "^UBUNTU_CODENAME" | cut -d"=" -f2)" != "noble" ]]; then
  log_info "Maybe a PPA could be used here..."
fi

if ! grep -rq "nushell" /etc/apt/sources.list*; then
  log_info "Adding nushell repository..."
  sudo install -dm 755 /etc/apt/keyrings
  wget -qO- https://apt.fury.io/nushell/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/fury-nushell.gpg
  echo "deb [signed-by=/etc/apt/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /" | sudo tee /etc/apt/sources.list.d/fury-nushell.list
fi

if ! command -v nushell &>/dev/null; then
  log_info "Installing nushell..."
  sudo apt update
  sudo apt install -y nushell
  log_info "Nushell installed"
fi

# # Integrate with fish
# FISH_COMPLETIONS_DIR="/usr/share/fish/vendor_completions.d"
# mkdir --parents --verbose "$FISH_COMPLETIONS_DIR" &&
#   nushell completion fish | sudo tee "$FISH_COMPLETIONS_DIR/nushell.fish" 1>/dev/null
