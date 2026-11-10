#!/usr/bin/env bash
# Trust the homelab proxy's internal CA, so https://*.home.arpa stops warning.
#
# Fetched over plain HTTP by the node's MagicDNS name: a client cannot verify a
# certificate before it trusts the root, and the name survives the tailnet
# address changing. WireGuard encrypts this hop. Gated on reachability, so a
# machine off the tailnet skips instead of failing the bootstrap, and silent
# once the root is installed.
#
# Runs after 25_tailscale.sh, which brings the tailnet up.
set -euo pipefail

url=http://nuc.taila191ac.ts.net/root.crt
name=homelab-ca.crt
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

curl -fsS --max-time 5 "$url" -o "$tmp" 2>/dev/null || exit 0

# Capability, not distro: whichever trust tool this machine has.
if command -v update-ca-certificates >/dev/null; then
  dest=/usr/local/share/ca-certificates/$name
  refresh=(update-ca-certificates)
elif command -v trust >/dev/null; then
  dest=/etc/ca-certificates/trust-source/anchors/$name
  refresh=(trust extract-compat)
else
  log warn "homelab-ca: no trust-store tool found, skipping"
  exit 0
fi

cmp -s "$tmp" "$dest" && exit 0

# sudo asks for a fingerprint or password, which needs a terminal; failing here
# would abort every step after this one.
if [[ ! -t 0 ]] && ! sudo -n true 2>/dev/null; then
  log warn "homelab-ca: needs sudo; run 'yadm bootstrap' from a terminal"
  exit 0
fi

sudo install -Dm 0644 "$tmp" "$dest"
sudo "${refresh[@]}" >/dev/null

log info "Trusted the homelab CA"
