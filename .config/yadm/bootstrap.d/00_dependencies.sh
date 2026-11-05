#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
DEPENDENCIES_FILE=${SCRIPT_DIR}/dependencies.txt

# One entry per line: the command to look for, then its package when the names differ.
missing_pkgs=()
while read -r cmd pkg; do
  command -v "$cmd" &> /dev/null || missing_pkgs+=("${pkg:-$cmd}")
done < <(grep --invert-match -E '^\s*#|^$' "$DEPENDENCIES_FILE")

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
