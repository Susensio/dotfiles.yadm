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
  pkg-install "${missing_pkgs[@]}"
  log info "Missing packages installed"
fi

# mise's aur: backend builds with yay or paru and installs base-devel itself
# neither, so a missing helper or toolchain fails the packages step mid-run
# rather than here (ADR-0102). Only machines whose config declares one are
# asked: the declaration is the capability, and grep is on every machine.
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/mise
if grep -qs '^"aur:' "$config_dir"/conf.d/*.toml; then
  missing_prerequisites=()
  command -v yay &>/dev/null || command -v paru &>/dev/null || missing_prerequisites+=(yay-or-paru)
  pacman -Q base-devel &>/dev/null || missing_prerequisites+=(base-devel)
  if (( ${#missing_prerequisites[@]} > 0 )); then
    log error "Missing ${missing_prerequisites[*]} for mise's aur: packages (ADR-0102)"
    exit 1
  fi
fi
