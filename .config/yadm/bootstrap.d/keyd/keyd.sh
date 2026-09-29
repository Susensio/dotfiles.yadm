#!/usr/bin/env bash
set -euo pipefail

SYSTEM_CONFIG=/etc/keyd/default.conf
USER_CONFIG=${XDG_CONFIG_HOME:-${HOME}/.config}/keyd/default.conf
ASSETS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets
USER_SYSTEMD_DIR=${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user

# Ubuntu 24.04, Mint 22's base, does not package keyd
if command -v apt-get &>/dev/null && ! grep -rq "keyd-team" /etc/apt/sources.list*; then
  log info "Adding keyd repository..."
  sudo add-apt-repository -y ppa:keyd-team/ppa
fi

if ! command -v keyd &>/dev/null && ! command -v keyd.rvaiya &>/dev/null; then
  log info "Installing keyd..."
  pkg-install keyd
  log success "Keyd installed"
fi

if ! command -v keyd &>/dev/null && command -v keyd.rvaiya &>/dev/null; then
  log info "Symlinking keyd because it is installed as keyd.rvaiya..."
  sudo ln -srf /usr/bin/keyd.rvaiya /usr/bin/keyd
  sudo ln -srf /usr/share/man/man1/keyd.rvaiya.1.gz /usr/share/man/man1/keyd.1.gz
  sudo mandb --quiet
fi

if ! systemctl is-enabled --quiet keyd || ! systemctl is-active --quiet keyd; then
  log info "Enabling keyd..."
  sudo systemctl enable --now keyd
fi

# setfacl below needs the file; reconcile drift even before the next edit.
config_changed=false
if [[ ! -f $SYSTEM_CONFIG ]]; then
  sudo install --mode 644 -D "$USER_CONFIG" "$SYSTEM_CONFIG"
  config_changed=true
elif ! cmp -s "$USER_CONFIG" "$SYSTEM_CONFIG"; then
  sudo cp "$USER_CONFIG" "$SYSTEM_CONFIG"
  config_changed=true
fi

# I want `keyd` to be managed by user and tracked by yadm
# symlink wont work because git wont track it, and $HOME may be encrypted.
# Solution: use a user config and sync it using a systemd service

# Let user manage keyd without password. Not every package creates the group.
getent group keyd &>/dev/null || sudo groupadd --system keyd
if ! id -nG "$USER" | grep -qw keyd; then
  log info "Adding $USER to the keyd group..."
  sudo usermod -aG keyd "$USER"
fi

# Give $USER permissions to manage keyd
if ! getfacl --omit-header "$SYSTEM_CONFIG" 2>/dev/null | grep -q "^user:$USER:rw"; then
  sudo setfacl -m "u:$USER:rw" "$SYSTEM_CONFIG"
fi
if $config_changed; then
  sudo keyd reload
fi

# --- Systemd Sync Setup ---
units_changed=false
for unit in keyd-sync.path keyd-sync.service; do
  if ! cmp -s "$ASSETS_DIR/$unit" "$USER_SYSTEMD_DIR/$unit"; then
    install -Dv --mode=644 "$ASSETS_DIR/$unit" "$USER_SYSTEMD_DIR/$unit"
    units_changed=true
  fi
done
if $units_changed; then
  systemctl --user daemon-reload
  systemctl --user restart keyd-sync.path
fi
if ! systemctl --user is-enabled --quiet keyd-sync.path; then
  systemctl --user enable --now keyd-sync.path
  log success "Keyd sync configured"
fi
