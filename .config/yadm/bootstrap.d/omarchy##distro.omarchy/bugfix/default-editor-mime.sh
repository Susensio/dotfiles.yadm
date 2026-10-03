#!/usr/bin/env bash
# omarchy-default-editor records the pick for Omarchy's launchers only, so file
# managers keep opening text files in whatever mimeapps.list names (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/7446; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch default-editor-mime.patch /usr/bin/omarchy-default-editor 1

# Where omarchy-refresh-applications copies the packaged entries
install_omarchy_file omarchy-launch-editor.desktop \
  "${XDG_DATA_HOME:-$HOME/.local/share}/applications/omarchy-launch-editor.desktop" 644 \
  /usr/share/omarchy/applications/omarchy-launch-editor.desktop
