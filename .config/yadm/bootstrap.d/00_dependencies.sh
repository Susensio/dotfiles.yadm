#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
DEPENDENCIES_FILE=${SCRIPT_DIR}/dependencies.txt

required=()
readarray -t required < <(grep --invert-match -E '^\s*#|^$' "$DEPENDENCIES_FILE")

# Each line is a command, then its package when the names differ
missing_pkgs=()
for line in "${required[@]}"; do
  read -r cmd pkg <<<"$line"
  if ! command -v "$cmd" &> /dev/null; then
    missing_pkgs+=("${pkg:-$cmd}")
  fi
done

if (( ${#missing_pkgs[@]} > 0 )); then
  log info "Installing missing packages..."
  pkg-install "${missing_pkgs[@]}"
  log info "Missing packages installed"
fi
