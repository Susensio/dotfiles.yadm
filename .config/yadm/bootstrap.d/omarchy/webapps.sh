#!/usr/bin/env bash
# Web-app launcher entries we keep from Omarchy's preinstalls. They install
# through omarchy-webapp-install and run after preinstalls.sh, whose
# omarchy-webapp-remove-all would otherwise sweep them.
# Gmail, the mailto: handler, is installed by mime.sh instead.
set -euo pipefail

command -v omarchy-webapp-install &>/dev/null || exit 0

APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
webapp() { [[ -f $APPS/$1.desktop ]] || omarchy-webapp-install "$@"; }
webapp "ChatGPT" https://chatgpt.com/ chatgpt
webapp "Gemini" https://gemini.google.com/ https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-gemini.png
webapp "GitHub" https://www.github.com
webapp "Google Maps" https://maps.google.com google-maps
webapp "Google Photos" https://photos.google.com/ google-photos
webapp "WhatsApp" https://web.whatsapp.com/ whatsapp
webapp "YouTube" https://youtube.com/ youtube
