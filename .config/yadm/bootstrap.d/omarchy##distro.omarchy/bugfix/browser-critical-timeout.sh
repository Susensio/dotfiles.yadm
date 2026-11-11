#!/usr/bin/env bash
# Chromium sends web pushes critical, which the notification shell never expires; a browser's critical
# gets the normal lifetime instead (docs/adr/0114).
# https://github.com/omacom/omarchy/pull/16689; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch browser-critical-Service.patch /usr/share/omarchy/shell/plugins/notifications/Service.qml 0
apply_omarchy_patch browser-critical-Store.patch /usr/share/omarchy/shell/plugins/notifications/Store.js 0
