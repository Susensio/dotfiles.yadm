#!/usr/bin/env bash
set -euo pipefail

source "${HOME}/bin/log"
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
DEPENDENCIES_FILE=${SCRIPT_DIR}/dependencies.txt

required_pkgs=()
readarray -t required_pkgs < <(grep --invert-match -E '^\s*#|^$' "$DEPENDENCIES_FILE")

missing_pkgs=()
for pkg in "${required_pkgs[@]}"; do
  if ! command -v "$pkg" &> /dev/null; then
    missing_pkgs+=("$pkg")
  fi
done

if (( ${#missing_pkgs[@]} > 0 )); then
  log_info "Installing missing packages..."
  sudo apt update && sudo apt install -y "${missing_pkgs[@]}"
  log_info "Missing packages installed"
fi
