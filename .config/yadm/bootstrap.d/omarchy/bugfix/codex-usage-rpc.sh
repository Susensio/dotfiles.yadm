#!/usr/bin/env bash
# Buffered readline hides batched Codex replies from select(), causing usage timeouts (docs/adr/0057).
# https://github.com/omacom/omarchy/pull/12979; delete this step once it ships
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch \
  codex-usage-rpc.patch \
  "$(realpath /usr/share/omarchy/bin/omarchy-agent-usage-codex)" 1
