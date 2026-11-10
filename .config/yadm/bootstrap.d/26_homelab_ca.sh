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

# Steps normally run under bootstrap, which defines log.
declare -F log >/dev/null || log() { printf '%s\n' "$*"; }

url=http://nuc.taila191ac.ts.net/root.crt
name=homelab-ca.crt
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

curl -fsS --max-time 5 "$url" -o "$tmp" 2>/dev/null || exit 0

# Capability, not distro: whichever trust tool this machine has.
if command -v update-ca-certificates >/dev/null; then
  dest=/usr/local/share/ca-certificates/$name
  cmp -s "$tmp" "$dest" && exit 0
  sudo install -Dm 0644 "$tmp" "$dest"
  sudo update-ca-certificates >/dev/null
elif command -v trust >/dev/null; then
  dest=/etc/ca-certificates/trust-source/anchors/$name
  cmp -s "$tmp" "$dest" && exit 0
  sudo install -Dm 0644 "$tmp" "$dest"
  sudo trust extract-compat >/dev/null
else
  log "homelab-ca: no trust-store tool found, skipping"
  exit 0
fi

log "Trusted the homelab CA"
