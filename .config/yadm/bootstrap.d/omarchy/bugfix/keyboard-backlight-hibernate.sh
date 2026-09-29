#!/usr/bin/env bash
# Omarchy's pre-hibernate hook zeroes the keyboard backlight and never restores it on resume.
# https://github.com/omacom/omarchy/pull/13729; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch \
  keyboard-backlight-hibernate.patch \
  /usr/lib/systemd/system-sleep/keyboard-backlight 0
