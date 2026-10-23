#!/usr/bin/env bash
# TRIM reaches an SSD under LUKS only if the mapping allows discards; the LUKS2
# header flag survives Omarchy rewriting the cmdline (docs/adr/0098). Setting it
# needs the passphrase, so this only warns: run the printed command once.
set -euo pipefail

root=$(findmnt -no SOURCE / | sed 's/\[.*//')
[[ $(lsblk -dno TYPE "$root" 2>/dev/null) == crypt ]] || exit 0
(($(lsblk -bdno DISC-MAX "$root") == 0)) || exit 0
# Only worth it when the disk under the mapping can discard at all
(($(lsblk -sbno DISC-MAX "$root" | sed -n 2p) > 0)) || exit 0

log warn "LUKS mapping $(basename "$root") drops TRIM; run once: sudo cryptsetup refresh --allow-discards --persistent $(basename "$root")"
