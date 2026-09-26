#!/usr/bin/env bash
# Keep EDITOR in tools.conf in step with the editor picked in Omarchy's menu
# (docs/adr/0047): install assets/omarchy-editor-sync and the watcher that runs it,
# and seed Omarchy's pick.
set -euo pipefail

command -v omarchy-default-editor &>/dev/null || exit 0

STATE=${XDG_STATE_HOME:-${HOME}/.local/state}/omarchy/defaults/editor
TOOLS_ENV=${XDG_CONFIG_HOME:-${HOME}/.config}/environment.d/tools.conf
USER_SYSTEMD_DIR=${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user
SYNC=$HOME/.local/libexec/omarchy-editor-sync

install -D --mode=755 "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets/omarchy-editor-sync" "$SYNC"

mkdir --parents "$USER_SYSTEMD_DIR"

cat <<-EOF >"$USER_SYSTEMD_DIR/omarchy-editor-sync.path"
	[Unit]
	Description=Watch Omarchy's default editor

	[Path]
	PathChanged=$STATE

	[Install]
	WantedBy=default.target
EOF

cat <<-EOF >"$USER_SYSTEMD_DIR/omarchy-editor-sync.service"
	[Unit]
	Description=Copy Omarchy's default editor into environment.d

	[Service]
	Type=oneshot
	ExecStart=$SYNC
EOF

systemctl --user daemon-reload
systemctl --user enable --now omarchy-editor-sync.path

# Seed from tools.conf, not $EDITOR: in an Omarchy session that is uwsm's launcher
if [[ ! -f $STATE ]]; then
  omarchy-default-editor "$(sed -n 's/^EDITOR=//p' "$TOOLS_ENV")"
fi
"$SYNC"

log success "Omarchy editor sync configured"
