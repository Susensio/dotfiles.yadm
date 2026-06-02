#!/usr/bin/env bash
set -euo pipefail

source "${HOME}/bin/log"

SYSTEM_CONFIG=/etc/keyd/default.conf
USER_CONFIG=${XDG_CONFIG_HOME:-${HOME}/.config}/keyd/default.conf

SUDOERS_FILE=/etc/sudoers.d/keyd-nopasswd
USER_SYSTEMD_DIR=${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user
WATCHER_UNIT=$USER_SYSTEMD_DIR/keyd-sync.path
SYNCER_UNIT=$USER_SYSTEMD_DIR/keyd-sync.service

if ! command -v keyd.rvaiya &>/dev/null; then
  log_info "Installing keyd..."
  sudo apt update
  sudo apt install keyd

  log_info "Symlinking keyd because it is installed as keyd.rvaiya..."
  sudo ln -srfv /usr/bin/keyd.rvaiya /usr/bin/keyd
  sudo ln -srfv /usr/share/man/man1/keyd.rvaiya.1.gz /usr/share/man/man1/keyd.1.gz
  sudo mandb

  log_success "Keyd installed"
fi

# I want `keyd` to be managed by user and tracked by yadm
# symlink wont work because git wont track it, and $HOME may be encrypted.
# Solution: use a user config and sync it using a systemd service


# Let user manage keyd without password
sudo usermod -aG keyd "$USER"
# if [[ ! -f "$SUDOERS_FILE" ]]; then
#   echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/keyd reload" |
#     sudo install --mode 440 --verbose /dev/stdin "$SUDOERS_FILE"
# fi

# Give $USER permissions to manage keyd
sudo setfacl -m u:$USER:rw /etc/keyd/default.conf


# --- Systemd Sync Setup ---
if [[ -f "$WATCHER_UNIT" && -f "$SYNCER_UNIT" ]]; then
  exit
fi

log_info "Writing systemd units to keep keyd user config in sync with system config"

mkdir --parents "$USER_SYSTEMD_DIR"

cat <<-EOF >"$WATCHER_UNIT"
  [Unit]
  Description=Watch for keyd config changes in home dir

  [Path]
  PathModified=$USER_CONFIG

  [Install]
  WantedBy=default.target
EOF

cat <<-EOF >"$SYNCER_UNIT"
  [Unit]
  Description=Sync keyd config to system space

  [Service]
  Type=oneshot
  ExecStart=/usr/bin/cp --update "$USER_CONFIG" "$SYSTEM_CONFIG"
EOF

systemctl --user daemon-reload
systemctl --user enable --now keyd-sync.path

log_success "Keyd sync configured"
