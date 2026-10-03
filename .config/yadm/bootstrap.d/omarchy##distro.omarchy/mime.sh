#!/usr/bin/env bash
# Desktop defaults that replace Omarchy's: Gmail for mailto: instead of HEY, whose
# launcher preinstalls.sh removes, and the menu's editor instead of nvim for text files.
# omarchy-provision-user resets mailto to HEY, so this runs on every bootstrap.
set -euo pipefail

command -v omarchy-webapp-install &>/dev/null || exit 0

APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
MIMEAPPS=${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list

MAILTO=$HOME/.local/libexec/gmail-mailto
install -DCv --mode=755 "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets/gmail-mailto" "$MAILTO"
if [[ ! -f $APPS/Gmail.desktop ]]; then
  omarchy-webapp-install "Gmail" https://mail.google.com/ "" "$MAILTO %u" "x-scheme-handler/mailto;"
fi

# Set a default only where mimeapps.list names another handler
set_default() {
  local app=$1 type
  shift
  for type; do
    grep -qxF "$type=$app" "$MIMEAPPS" 2>/dev/null || xdg-mime default "$app" "$type"
  done
}

set_default Gmail.desktop x-scheme-handler/mailto

# The types Omarchy's system mimeapps.list gives nvim; the handler from
# bugfix/default-editor-mime.sh opens them in omarchy-default-editor's pick
readarray -t text_types < <(sed -n 's/=nvim\.desktop$//p' /usr/share/applications/mimeapps.list)
set_default omarchy-launch-editor.desktop "${text_types[@]}"
