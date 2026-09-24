#!/usr/bin/env bash
set -euo pipefail

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
  log info "Installing missing packages..."
  sudo apt update && sudo apt install -y "${missing_pkgs[@]}"
  log info "Missing packages installed"
fi
