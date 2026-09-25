#!/usr/bin/env bash
# Trim Omarchy's preinstalls to the apps actually used. Mirrors
# omarchy-remove-preinstalls without its prompt, and without its blanket rm over
# ~/.local/bin, where mise.sh links our own claude, codex, gh...
# TODO: mise bootstrap can declare pacman packages as installed or absent
# (https://mise.jdx.dev/bootstrap/packages/pacman.html); move the packages there
# once it also covers Omarchy's launchers.
set -euo pipefail

command -v omarchy-pkg-drop &>/dev/null || exit 0

# Omarchy's own opt-out marker: it also drops the keybindings for removed apps
MARKER=$HOME/.local/state/omarchy/preinstalls-removed
if [[ ! -e $MARKER ]]; then
  omarchy-webapp-remove-all
  omarchy-tui-remove-all
  omarchy-pkg-drop cliamp xournalpp obsidian obs-studio kdenlive moonlight-qt \
    lazydocker omacut omawrite
  mkdir --parents "$(dirname "$MARKER")"
  touch "$MARKER"
  hyprctl reload &>/dev/null || true
fi

# Icons are the ones Omarchy bundles under /usr/share/icons/hicolor
omarchy-webapp-install "Google Maps" https://maps.google.com google-maps
omarchy-webapp-install "Google Photos" https://photos.google.com/ google-photos
omarchy-webapp-install "WhatsApp" https://web.whatsapp.com/ whatsapp
omarchy-webapp-install "YouTube" https://youtube.com/ youtube
omarchy-tui-install "Disk Usage" 'bash -c "dua i /"' float disk-usage

# Omarchy's mise wrappers, which run `mise use -g` on every call; a real install
# or one of our links at the same path is left alone
for wrapper in codex claude agy copilot gh opencode playwright playwright-cli pi \
  omp ori grok crush ghui hunk cursor-agent muse hey basecamp cf; do
  wrapper=${XDG_BIN_HOME:-${HOME}/.local/bin}/$wrapper
  if [[ -f $wrapper && ! -L $wrapper ]] && grep -q '^mise use -g' "$wrapper"; then
    rm --verbose "$wrapper"
  fi
done
