#!/usr/bin/env bash
# Keep EDITOR in tools.conf in step with the editor picked in Omarchy's menu
# (docs/adr/0047): install assets/omarchy-editor-sync and the watcher that runs it,
# and seed Omarchy's pick.
set -euo pipefail

command -v omarchy-default-editor &>/dev/null || exit 0

ASSETS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets
STATE=${XDG_STATE_HOME:-${HOME}/.local/state}/omarchy/defaults/editor
TOOLS_ENV=${XDG_CONFIG_HOME:-${HOME}/.config}/environment.d/tools.conf
USER_SYSTEMD_DIR=${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user
SYNC=$HOME/.local/libexec/omarchy-editor-sync

cmp -s "$ASSETS_DIR/omarchy-editor-sync" "$SYNC" ||
  install -Dv --mode=755 "$ASSETS_DIR/omarchy-editor-sync" "$SYNC"

units_changed=false
for unit in omarchy-editor-sync.path omarchy-editor-sync.service; do
  if ! cmp -s "$ASSETS_DIR/$unit" "$USER_SYSTEMD_DIR/$unit"; then
    install -Dv --mode=644 "$ASSETS_DIR/$unit" "$USER_SYSTEMD_DIR/$unit"
    units_changed=true
  fi
done
if $units_changed; then
  systemctl --user daemon-reload
  systemctl --user restart omarchy-editor-sync.path
fi
if ! systemctl --user is-enabled --quiet omarchy-editor-sync.path; then
  systemctl --user enable --now omarchy-editor-sync.path
  log success "Omarchy editor sync configured"
fi

# Seed from tools.conf, not $EDITOR: in an Omarchy session that is uwsm's launcher
if [[ ! -f $STATE ]]; then
  omarchy-default-editor "$(sed -n 's/^EDITOR=//p' "$TOOLS_ENV")"
fi
# Catch up on a pick made while the watcher was off
if [[ $(<"$STATE") != "$(sed -n 's/^EDITOR=//p' "$TOOLS_ENV")" ]]; then
  "$SYNC"
fi
