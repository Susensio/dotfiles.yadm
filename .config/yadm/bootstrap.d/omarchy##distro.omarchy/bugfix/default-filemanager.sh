#!/usr/bin/env bash
# Omarchy hardcodes Nautilus as the file manager, with no Defaults entry to
# change it like the browser, terminal and editor have (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/10542; delete this step once it ships
# The PR also rebinds Omarchy's default SUPER + SHIFT + F, which hypr/hyprland.lua
# does not load; hypr/bindings.lua calls the launcher itself.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

for command in omarchy-default-filemanager omarchy-launch-filemanager omarchy-launch-filemanager-cwd; do
  install_omarchy_file "$command" "$HOME/.local/bin/$command" 755 "/usr/bin/$command"
done

apply_omarchy_patch filemanager-guard-reader.patch /usr/share/omarchy/shell/plugins/menu/MenuModel.js 1
# Rebased on 4.0.4, whose editor rows gained "when" guards; the PR's rows are unchanged.
apply_omarchy_patch filemanager-menu.patch /usr/share/omarchy/default/omarchy/omarchy-menu.jsonc 1
