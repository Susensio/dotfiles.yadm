#!/usr/bin/env bash
# Omarchy's uwsm env prepends mise's shims, ahead of ~/bin/overrides and
# ADR-0007's ~/.local/bin links, though env-bootstrap already appends them (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/13364; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch \
  uwsm-mise-shims.patch \
  /usr/share/uwsm/env.d/10-omarchy 0
