#!/usr/bin/env bash
# The night light indicator misses hyprsunset's scheduled switches until the shell re-probes (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/13684; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

nightlight=/usr/share/omarchy/shell/plugins/services/nightlight
apply_omarchy_patch nightlight-schedule-model.patch "$nightlight/NightlightModel.js" 1
apply_omarchy_patch nightlight-schedule-service.patch "$nightlight/Service.qml" 1
apply_omarchy_patch nightlight-probe-guard.patch "$nightlight/Service.qml" 1
