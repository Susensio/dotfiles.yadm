#!/usr/bin/env bash
# https://github.com/omacom/omarchy/pull/13743; remove when it ships.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

apply_omarchy_patch plugin-added-hook.patch "$(realpath /usr/share/omarchy/bin/omarchy-plugin-add)" 1
apply_omarchy_patch plugin-removed-hook.patch "$(realpath /usr/share/omarchy/bin/omarchy-plugin-remove)" 1
