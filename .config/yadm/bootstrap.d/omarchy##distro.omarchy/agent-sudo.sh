#!/usr/bin/env bash
# Agents' `sudo -A` (asroot over SSH) gets its own PAM service without Omarchy's fingerprint stage,
# which would wait 30 s with its cue hidden in the agent's output (docs/adr/0134-agent-root-asroot.md).
set -euo pipefail

ASSETS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets

PAM=/etc/pam.d/sudo-askpass
cmp -s "$ASSETS_DIR/pam-sudo-askpass" "$PAM" ||
  sudo install -Dv --mode=644 "$ASSETS_DIR/pam-sudo-askpass" "$PAM"

# The PAM service must exist before sudoers names it, or `sudo -A` has no stack to run.
SUDOERS=/etc/sudoers.d/50-agent-sudo
if ! sudo cmp -s "$ASSETS_DIR/sudoers-agent-sudo" "$SUDOERS"; then
  visudo -cqf "$ASSETS_DIR/sudoers-agent-sudo"
  sudo install -Dv --mode=440 "$ASSETS_DIR/sudoers-agent-sudo" "$SUDOERS"
fi

# The `asroot --yolo` window's timer is transient; clear a leftover grant at boot.
TMPFILES=/etc/tmpfiles.d/asroot-yolo.conf
cmp -s "$ASSETS_DIR/tmpfiles-asroot-yolo" "$TMPFILES" ||
  sudo install -Dv --mode=644 "$ASSETS_DIR/tmpfiles-asroot-yolo" "$TMPFILES"
