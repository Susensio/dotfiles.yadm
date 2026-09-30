#!/usr/bin/env bash
# Screensaver dismissal must not restore a stale brightness saved by an earlier lock.
# https://github.com/omacom/omarchy/pull/10364; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch \
  keyboard-backlight-restore.patch \
  /usr/bin/omarchy-brightness-keyboard 0
