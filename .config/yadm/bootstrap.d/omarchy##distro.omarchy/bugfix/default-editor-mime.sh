#!/usr/bin/env bash
# Omarchy's system mimeapps.list sends text files to nvim.desktop, so file managers
# open them in Neovim whatever omarchy-default-editor picked (docs/adr/0057). The
# patch sends them to the editor handler, which launches the menu's pick, and
# keeps nvim.desktop as the fallback until the handler is installed.
# https://github.com/omacom/omarchy/pull/7446 (reworked as a suggestion:
# https://github.com/Susensio/omarchy/commits/default-editor-handler-review);
# delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch editor-mimeapps.patch /usr/share/applications/mimeapps.list 1

# Where omarchy-refresh-applications copies the packaged entries
install_omarchy_file omarchy-launch-editor.desktop \
  "${XDG_DATA_HOME:-$HOME/.local/share}/applications/omarchy-launch-editor.desktop" 644 \
  /usr/share/omarchy/applications/omarchy-launch-editor.desktop
