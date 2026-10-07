#!/usr/bin/env bash
# Restore missing declared clones without changing their source list (ADR-0072).
set -euo pipefail

command -v omarchy &>/dev/null || exit 0

config=$HOME/.config/omarchy
sources=$config/plugins.conf
[[ -f $sources ]] || exit 0

while IFS=$'\t' read -r id url; do
  [[ -z $id || $id == '#'* ]] && continue
  [[ -n $url && $id =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || {
    log error "Invalid Omarchy plugin declaration: $id"
    exit 1
  }
  [[ -e $config/plugins/$id || -L $config/plugins/$id ]] && continue
  log info "Installing Omarchy plugin $id"
  # Installs, then fails to rescan when no desktop session runs (SSH, TTY, CI)
  omarchy plugin add "$url" --yes || true
  [[ -f $config/plugins/$id/manifest.json ]] || {
    log error "Installed Omarchy plugin did not provide the declared id $id"
    exit 1
  }
done < "$sources"
