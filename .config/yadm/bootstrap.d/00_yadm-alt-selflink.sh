#!/usr/bin/env bash
# yadm 3.5.0's ln_relative() lost `ln -n`, so two overlapping auto-alt runs link a
# directory alternate inside itself, e.g. omarchy##distro.omarchy/omarchy##distro.omarchy.
# Numbered first: yadm's alternates run before the bootstrap, so a run that starts
# after another still finds the self-link last run left, wherever this sorts.
# https://github.com/yadm-dev/yadm/pull/550 (report: issue #549); once a yadm release
# carries it (merged is not released: compare `yadm version`), delete this step.
set -euo pipefail

while IFS= read -r -d '' link; do
  [[ ${link##*/} == "$(basename -- "$(dirname -- "$link")")" ]] || continue
  rm -- "$link"
  log info "Removed yadm's self-link ${link#"${XDG_CONFIG_HOME:-$HOME/.config}"/}"
done < <(find "${XDG_CONFIG_HOME:-$HOME/.config}/yadm" -mindepth 2 -type l -name '*##*' -print0)
