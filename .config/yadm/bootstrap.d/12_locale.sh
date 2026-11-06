#!/usr/bin/env bash
# environment.d/12_locale.conf exports LC_TIME=en_GB.UTF-8 so shell dates start
# weeks on Monday (docs/adr/0091). The locale has to exist in glibc's archive
# first: an ungenerated name makes LC_TIME consumers warn and fall back to C.
# Generating it is root work, so it happens here.
set -euo pipefail

command -v locale-gen >/dev/null || exit 0
locale -a | grep -qx 'en_GB.utf8' && exit 0

# sed is idempotent, and locale-gen exits 0 with the entry still commented out
sudo sed -i -E 's/^#[[:space:]]*(en_GB\.UTF-8[[:space:]])/\1/' /etc/locale.gen
sudo locale-gen
