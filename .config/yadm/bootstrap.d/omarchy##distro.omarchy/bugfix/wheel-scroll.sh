#!/usr/bin/env bash
# Omarchy's menus and emoji picker are Qt Flickables whose wheel step is fixed,
# so a touchpad crawls through long lists (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/8959; delete this step once it ships
# The PR's shared WheelScrollArea component would be a new file under /usr
# (docs/adr/0082) that the menus must import from the package's own module, so
# each list carries the same MouseArea inline.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch wheel-scroll-menu.patch /usr/share/omarchy/shell/plugins/menu/Menu.qml 1
apply_omarchy_patch wheel-scroll-emojis.patch /usr/share/omarchy/shell/plugins/emojis/Emojis.qml 1
