#!/usr/bin/env bash
# Desktop defaults that replace Omarchy's: Gmail for mailto: instead of HEY, whose
# launcher preinstalls.sh removes, and Helix instead of nvim for text files.
# omarchy-provision-user resets mailto to HEY, so this runs on every bootstrap.
set -euo pipefail

command -v omarchy-webapp-install &>/dev/null || exit 0

MAILTO=$HOME/.local/libexec/gmail-mailto
install -D --mode=755 "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets/gmail-mailto" "$MAILTO"
omarchy-webapp-install "Gmail" https://mail.google.com/ "" "$MAILTO %u" "x-scheme-handler/mailto;"
xdg-mime default Gmail.desktop x-scheme-handler/mailto

# The types Omarchy's system mimeapps.list gives nvim; Arch's helix ships Helix.desktop
readarray -t text_types < <(sed -n 's/=nvim\.desktop$//p' /usr/share/applications/mimeapps.list)
xdg-mime default Helix.desktop "${text_types[@]}"
