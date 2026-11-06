#!/usr/bin/env bash
# Omarchy's panel loader keeps a plugin's QML only while it is open unless the
# manifest sets keepLoaded, so every summon rebuilt Omamail's window (~1.3s here, ADR-0106).
# https://github.com/huacnlee/omamail/pull/464; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

manifest=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/omamail/manifest.json
[[ -f $manifest ]] || exit 0
grep -q '"keepLoaded"' "$manifest" && exit 0

# One inserted line, so the clone's local change stays a one-line diff against
# the manifest upstream ships.
sed -i '/^  "id": "omamail",$/a\  "keepLoaded": true,' "$manifest"
grep -q '"keepLoaded"' "$manifest" || {
  log warn "omamail manifest shape changed: drop this step or patch it by hand"
  exit 0
}
log info "omamail: declared keepLoaded so its panel survives between summons"
omarchy-shell -q shell rescanPlugins
