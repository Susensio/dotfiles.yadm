#!/usr/bin/env bash
# Refresh pi's model catalog cache so the models named in settings.json and
# model-alias.json resolve on a machine that has never run pi.
# pi only refreshes when the model selector opens in the TUI, so a machine
# driven headlessly, or freshly cloned, keeps the catalog bundled with the
# installed version. That catalog lags the providers: a model added after the
# release warns "No models match pattern", and an alias targeting it silently
# loses a rung rather than failing. ADR-0092.
#
# Gated to once a day: the refresh is a network round trip with a 15s timeout,
# and the bootstrap reruns on every `omarchy update`.
set -euo pipefail

agent_dir=${PI_CODING_AGENT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pi/agent}
store=$agent_dir/models-store.json

if ! command -v pi >/dev/null 2>&1; then
  log debug "pi is not installed yet; skipping the model catalog refresh."
  exit 0
fi

if [[ -n $(find "$store" -mtime -1 2>/dev/null) ]]; then
  exit 0
fi

# A failed refresh exits non-zero and must not abort the bootstrap: the cache is
# optional, pi falls back to the version's bundled catalog, and a network
# hiccup here would fail a run that otherwise succeeded. pi leaves an existing
# store in place when the refresh fails, so the retry costs nothing.
if output=$(pi update --models 2>&1); then
  log info "Refreshed pi's model catalogs"
else
  log warn "Could not refresh pi's model catalogs; keeping the cached catalog."
  log debug "$output"
fi
exit 0
