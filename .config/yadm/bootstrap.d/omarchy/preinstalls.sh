#!/usr/bin/env bash
# Trim Omarchy's preinstalls to the apps actually used. Mirrors
# omarchy-remove-preinstalls without its prompt, and without its blanket rm over
# ~/.local/bin, where mise.sh links our own claude, codex, gh... The packages are
# mise/conf.d/omarchy.toml##distro.omarchy's, applied by mise.sh.
set -euo pipefail

command -v omarchy-webapp-remove-all &>/dev/null || exit 0

# Omarchy's own opt-out marker: it also drops the keybindings for removed apps
MARKER=$HOME/.local/state/omarchy/preinstalls-removed
if [[ ! -e $MARKER ]]; then
  omarchy-webapp-remove-all
  omarchy-tui-remove-all
  # Omarchy's mise wrappers, which run `mise use -g` on every call; a real install
  # or one of our links at the same path is left alone. Omarchy's migrations skip
  # re-adding them once the marker exists.
  for wrapper in codex claude agy gemini copilot gh opencode playwright playwright-cli \
    pi omp ori grok crush ghui hunk cursor-agent muse hey basecamp cf; do
    wrapper=${XDG_BIN_HOME:-${HOME}/.local/bin}/$wrapper
    if [[ -f $wrapper && ! -L $wrapper ]] && grep -q '^mise use -g' "$wrapper"; then
      rm --verbose "$wrapper"
    fi
  done
  # Hermes' launcher carries its installer's marker instead; --owns checks it for us
  if command -v omarchy-install-hermes-cli &>/dev/null && omarchy-install-hermes-cli --owns; then
    rm --force --verbose "${XDG_BIN_HOME:-${HOME}/.local/bin}/hermes"
  fi
  mkdir --parents "$(dirname "$MARKER")"
  touch "$MARKER"
  hyprctl reload &>/dev/null || true
fi

# Icons are the ones Omarchy bundles under /usr/share/icons/hicolor; Gmail, the
# mailto: handler, is installed by mime.sh
omarchy-webapp-install "Google Maps" https://maps.google.com google-maps
omarchy-webapp-install "Google Photos" https://photos.google.com/ google-photos
omarchy-webapp-install "WhatsApp" https://web.whatsapp.com/ whatsapp
omarchy-webapp-install "YouTube" https://youtube.com/ youtube
omarchy-tui-install "Disk Usage" 'bash -c "dua i /"' float disk-usage
