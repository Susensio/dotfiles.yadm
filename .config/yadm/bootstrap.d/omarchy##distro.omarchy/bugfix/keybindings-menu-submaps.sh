#!/usr/bin/env bash
# Omarchy's keybindings menu lists submap bindings as global chords; this
# prefixes them with the chord that enters their mode (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/13461; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch \
  keybindings-menu-submaps.patch \
  /usr/bin/omarchy-menu-keybindings 0
