#!/usr/bin/env bash
# Automatic brightness from the ambient light sensor and screen contents. wluma
# is AUR-only, so mise's pacman: backend cannot install it (ADR-0048). It ships
# a user unit and discovers the ALS and backlight itself, so no config file.
set -euo pipefail

command -v yay &>/dev/null || exit 0
compgen -G '/sys/bus/iio/devices/*/in_illuminance_raw' >/dev/null || exit 0

if ! pacman -Q wluma &>/dev/null; then
  log info "Installing wluma from the AUR..."
  yay -S --needed --noconfirm wluma
  log success "wluma installed"
fi

if ! systemctl --user is-enabled --quiet wluma.service; then
  systemctl --user enable --now wluma.service
  log success "wluma enabled"
fi
