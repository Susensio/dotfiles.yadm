#!/usr/bin/env bash
# Automatic brightness from the ambient light sensor and screen contents. The
# package is mise's (mise/conf.d/omarchy.toml##distro.omarchy, ADR-0102), so this
# step only enables it, and only where wluma can find something to drive. It
# ships a user unit and discovers the ALS and displays itself; the tracked
# wluma/config.toml only excludes the laptop keyboard backlight.
set -euo pipefail

command -v wluma &>/dev/null || exit 0
compgen -G '/sys/bus/iio/devices/*/in_illuminance_raw' >/dev/null || exit 0

if ! systemctl --user is-enabled --quiet wluma.service; then
  systemctl --user enable --now wluma.service
  log success "wluma enabled"
fi
