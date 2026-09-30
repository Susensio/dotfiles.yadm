#!/usr/bin/env bash
# Goodix 53xc readers (27c6:533c on this Dell, plus 530c, 538c, 5840) are on
# libfprint's "known unsupported" list, so Omarchy's fingerprint setup installs
# libfprint-git and then fails to enroll. Dell ships a proprietary TOD driver
# for them: swap libfprint-git for libfprint-tod plus that driver from the AUR,
# then let Omarchy do the enrollment and PAM wiring.
set -euo pipefail

command -v omarchy-setup-security-fingerprint &>/dev/null || exit 0

has_53xc_reader() {
  local dev
  for dev in /sys/bus/usb/devices/*; do
    [[ -r $dev/idVendor && $(<"$dev/idVendor") == 27c6 ]] || continue
    case $(<"$dev/idProduct") in 530c | 533c | 538c | 5840) return 0 ;; esac
  done
  return 1
}
has_53xc_reader || exit 0

DRIVER=libfprint-2-tod1-xps9300-bin
if ! pacman -Q libfprint-tod "$DRIVER" &>/dev/null; then
  log info "Installing Goodix 53xc fingerprint driver from the AUR..."
  # --ask 4 accepts replacing the conflicting libfprint-git, which --noconfirm
  # alone would refuse; --nocheck skips libfprint-tod's umockdev test suite.
  yay -S --needed --noconfirm --ask 4 --mflags --nocheck libfprint-tod "$DRIVER"
  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=usb --attr-match=idVendor=27c6
  log success "Goodix 53xc fingerprint driver installed"
fi

# Keep fprintd running from boot: see the asset for why
DROPIN=/etc/systemd/system/fprintd.service.d/no-timeout.conf
ASSET=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets/fprintd-no-timeout.conf
if ! cmp -s "$ASSET" "$DROPIN"; then
  sudo install -D --mode=644 "$ASSET" "$DROPIN"
  sudo systemctl daemon-reload
  sudo systemctl add-wants multi-user.target fprintd.service
  sudo systemctl restart fprintd
  log success "fprintd kept running for the fingerprint reader"
fi

if fprintd-list "$USER" 2>/dev/null | grep -q 'Fingerprints for user'; then
  exit 0
fi
if [[ ! -t 0 ]]; then
  log warn "No fingerprint enrolled; rerun bootstrap from a terminal to enroll"
  exit 0
fi

# Omarchy's setup reinstalls libfprint-git when it's missing, which would
# replace the TOD stack again; report its packages as present instead
shim=$(mktemp --directory)
printf '#!/bin/sh\nexit 1\n' >"$shim/omarchy-pkg-missing"
chmod +x "$shim/omarchy-pkg-missing"
PATH=$shim:$PATH omarchy-setup-security-fingerprint ||
  log warn "Fingerprint enrollment failed; rerun bootstrap to retry"
rm -rf "$shim"
