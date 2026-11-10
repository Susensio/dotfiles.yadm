#!/usr/bin/env bash
# A daemon plus, on apt, Tailscale's own repository: neither fits a declaration (docs/packages.md).
set -euo pipefail

# A container has the package but no service manager to run it
[[ -d /run/systemd/system ]] && systemd=true || systemd=false

# Arch packages tailscale; apt needs upstream's per-distro repository. No distro is
# named here: the first of ID and ID_LIKE with a published repository for our codename wins.
if command -v apt-get &>/dev/null && ! command -v tailscale &>/dev/null \
   && ! grep -rq "pkgs.tailscale.com" /etc/apt/sources.list*; then
  . /etc/os-release
  base=https://pkgs.tailscale.com/stable
  repo=
  for distro in $ID ${ID_LIKE:-}; do
    for codename in ${UBUNTU_CODENAME:-} ${VERSION_CODENAME:-}; do
      if curl -fsI "$base/$distro/$codename.noarmor.gpg" &>/dev/null; then
        repo=$distro/$codename
        break 2
      fi
    done
  done
  if [[ -z $repo ]]; then
    log warn "tailscale: no repository published for $ID ${VERSION_CODENAME:-}"
    exit 0
  fi
  log info "Adding Tailscale repository..."
  sudo install -d -m 0755 /usr/share/keyrings
  curl -fsSL "$base/$repo.noarmor.gpg" \
    | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL "$base/$repo.tailscale-keyring.list" \
    | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
fi

if ! command -v tailscale &>/dev/null; then
  log info "Installing Tailscale..."
  pkg-install tailscale
  log success "Tailscale installed"
fi

$systemd || exit 0

if ! systemctl is-enabled --quiet tailscaled || ! systemctl is-active --quiet tailscaled; then
  log info "Enabling tailscaled..."
  sudo systemctl enable --now tailscaled
fi

# Lets `omarchy tailscale send` and `receive` run without sudo
if ! tailscale debug prefs 2>/dev/null | grep -q "\"OperatorUser\": \"$USER\""; then
  sudo tailscale set --operator="$USER"
fi

# Login needs a browser, so it stays a manual step
if [[ $(tailscale status --json 2>/dev/null | jq -r .BackendState) == NeedsLogin ]]; then
  log warn "tailscale: not logged in; run 'tailscale up'"
  exit 0
fi

# Meshing machines needs the server, not the client, so this is what makes
# `ssh` to any of them work without keys (docs/adr/0109). The policy half
# cannot live here: no local tailscale subcommand reads or writes the ACL.
if ! tailscale debug prefs 2>/dev/null | grep -q '"RunSSH": true'; then
  log info "Enabling Tailscale SSH..."
  tailscale set --ssh
fi
