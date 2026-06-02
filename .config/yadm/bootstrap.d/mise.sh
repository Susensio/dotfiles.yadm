#!/usr/bin/env bash
set -euo pipefail

source "${HOME}/bin/log"

if [[ "$(cat /etc/os-release | grep "^UBUNTU_CODENAME" | cut -d"=" -f2)" != "noble" ]]; then
  log_info "Maybe a PPA could be used here..."
fi

if ! grep -rq "mise" /etc/apt/sources.list*; then
  log_info "Adding mise repository..."
  sudo install -dm 755 /etc/apt/keyrings
  curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.pub 1>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
fi


if ! command -v mise &>/dev/null; then
  log_info "Installing mise..."
  sudo apt update
  sudo apt install -y mise
  log_info "mise installed"
fi

# Integrate with fish
FISH_COMPLETIONS_DIR="/usr/share/fish/vendor_completions.d"
mkdir --parents --verbose "$FISH_COMPLETIONS_DIR" &&
  mise completion fish | sudo tee "$FISH_COMPLETIONS_DIR/mise.fish" 1>/dev/null
