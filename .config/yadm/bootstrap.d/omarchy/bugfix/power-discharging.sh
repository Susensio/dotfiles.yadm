#!/usr/bin/env bash
# Trust the battery state once a plug change settles; UCSI can leave line power online after unplugging.
# https://github.com/omacom/omarchy/pull/13016; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch power-discharging-model.patch /usr/share/omarchy/shell/plugins/panels/power/Model.js 0
apply_omarchy_patch power-discharging-panel.patch /usr/share/omarchy/shell/plugins/panels/power/Panel.qml 0
