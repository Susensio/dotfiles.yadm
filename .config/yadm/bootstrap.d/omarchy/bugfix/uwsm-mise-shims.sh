#!/usr/bin/env bash
# Omarchy's uwsm env prepends mise's shims, ahead of ~/bin/overrides and
# ADR-0007's ~/.local/bin links, though env-bootstrap already appends them (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/13364; delete this step once it ships
set -euo pipefail

TARGET=/usr/share/uwsm/env.d/10-omarchy
PATCH=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets/uwsm-mise-shims.patch

[[ -f $TARGET ]] || exit 0

if patch -R -f -s -F0 --dry-run "$TARGET" <"$PATCH" &>/dev/null; then
  exit 0
elif ! patch -N -f -s -F0 --dry-run "$TARGET" <"$PATCH" &>/dev/null; then
  log warn "$(basename "$PATCH") no longer applies to Omarchy: check the PR and drop this step"
else
  sudo patch -N -f -F0 --no-backup-if-mismatch "$TARGET" <"$PATCH"
fi
