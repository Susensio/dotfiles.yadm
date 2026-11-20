#!/usr/bin/env bash
# TRIM reaches an SSD under LUKS only if the mapping allows discards; the LUKS2
# header flag survives Omarchy rewriting the cmdline (docs/adr/0098). Setting it
# needs the passphrase, so this only warns: run the printed command once.
set -euo pipefail

root=$(findmnt -no SOURCE / | sed 's/\[.*//')
# The crypt device is found by walking the chain, not by asking the root's own
# device: a host whose root sits on LVM (or any other layer) above the LUKS
# mapping would otherwise skip this check silently.  PATH keeps /dev/mapper/…
# intact so lsblk can read the mapping back.
crypt_dev=$(lsblk -sno PATH,TYPE "$root" 2>/dev/null | awk '$2 == "crypt" { print $1; exit }')
[[ -n $crypt_dev ]] || exit 0
(($(lsblk -bdno DISC-MAX "$crypt_dev") == 0)) || exit 0
# Only worth it when the disk under the mapping can discard at all; the last
# line of the inverse chain is the physical disk, whatever sits between.
(($(lsblk -sbno DISC-MAX "$crypt_dev" | tail -n1) > 0)) || exit 0

log warn "LUKS mapping $(basename "$crypt_dev") drops TRIM; run once: sudo cryptsetup refresh --allow-discards --persistent $(basename "$crypt_dev")"
