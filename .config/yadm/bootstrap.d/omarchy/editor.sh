#!/usr/bin/env bash
# Keep EDITOR in tools.conf in step with the editor picked in Omarchy's menu (docs/adr/0047).
#   editor.sh        install the watcher and seed Omarchy's pick (bootstrap step)
#   editor.sh sync   copy Omarchy's pick into tools.conf (run by the watcher)
set -euo pipefail

command -v omarchy-default-editor &>/dev/null || exit 0

STATE=${XDG_STATE_HOME:-${HOME}/.local/state}/omarchy/defaults/editor
TOOLS_ENV=${XDG_CONFIG_HOME:-${HOME}/.config}/environment.d/tools.conf
USER_SYSTEMD_DIR=${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user

sync() {
  local editor
  read -r editor <"$STATE"

  # $EDITOR readers wait on a terminal editor; these are the ones omarchy-launch-editor
  # runs in the terminal. A GUI pick keeps the previous value.
  case ${editor##*/} in
    nvim | vim | nano | micro | hx | helix | fresh) ;;
    *) return 0 ;;
  esac

  # SUDO_EDITOR follows, since tools.conf defines it from $EDITOR
  sed -i "s|^EDITOR=.*|EDITOR=$editor|" "$TOOLS_ENV"
  systemctl --user daemon-reload
}

setup() {
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
	ExecStart=$(realpath "${BASH_SOURCE[0]}") sync
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now omarchy-editor-sync.path

  # Seed from tools.conf, not $EDITOR: in an Omarchy session that is uwsm's launcher
  if [[ ! -f $STATE ]]; then
    omarchy-default-editor "$(sed -n 's/^EDITOR=//p' "$TOOLS_ENV")"
  fi
  sync

  log success "Omarchy editor sync configured"
}

case ${1:-} in
  sync) sync ;;
  "") setup ;;
  *)
    echo "Usage: ${0##*/} [sync]" >&2
    exit 1
    ;;
esac
