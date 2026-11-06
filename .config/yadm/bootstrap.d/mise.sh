#!/usr/bin/env bash
set -euo pipefail

if command -v apt-get &>/dev/null && ! grep -rq "mise" /etc/apt/sources.list*; then
  log info "Adding mise repository..."
  pkg-install extrepo
  sudo extrepo enable mise
fi


if ! command -v mise &>/dev/null; then
  log info "Installing mise..."
  pkg-install mise
  log info "mise installed"
fi

# Integrate with fish. User vendor dir, so it never overwrites a packaged copy.
FISH_COMPLETIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fish/vendor_completions.d"
mkdir --parents "$FISH_COMPLETIONS_DIR"
mise completion fish >"$FISH_COMPLETIONS_DIR/mise.fish"

# Machine-wide: every [bootstrap.packages] entry mise loads, not only tool's files.
# services carries the tool-update unit that `auto_update` relies on (ADR-0007).
# The bootstrap pipes stderr through tee, and mise refuses to ask for a sudo password
# unless stderr is a terminal, so cache it first. Only when packages differ: reruns stay silent.
mise bootstrap packages status --missing &>/dev/null || sudo -v

# --quiet would hide the downloads and hooks worth watching in a debug run
quiet=(--quiet)
[[ -n ${DEBUG:-} ]] && quiet=()

# A container has no systemd to hold services
only=packages,tools
[[ -d /run/systemd/system ]] && only+=,services

mise bootstrap --only "$only" --yes "${quiet[@]}"
