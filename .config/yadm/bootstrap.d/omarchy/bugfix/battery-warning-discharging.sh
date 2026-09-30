#!/usr/bin/env bash
# Warn when the battery drains even if a stale or underpowered line source says AC is online.
# https://github.com/omacom/omarchy/pull/11161; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch battery-warning-discharging.patch /usr/share/omarchy/shell/plugins/services/battery/BatteryModel.js 0
