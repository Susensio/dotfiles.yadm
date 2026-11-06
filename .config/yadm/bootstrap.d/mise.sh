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
# `status --missing` exits 0 only when every package matches, absent ones included, and
# the packages pass is then a no-op that still costs seconds and runs its hooks, so skip it.
# Otherwise the bootstrap pipes stderr through tee, and mise refuses to ask for a sudo
# password unless stderr is a terminal, so cache it first.
only=tools
if ! mise bootstrap packages status --missing &>/dev/null; then
  sudo -v
  only=packages,tools
fi

# --quiet would hide the downloads and hooks worth watching in a debug run
quiet=(--quiet)
[[ -n ${DEBUG:-} ]] && quiet=()

# A container has no systemd to hold services
[[ -d /run/systemd/system ]] && only+=,services

mise bootstrap --only "$only" --yes "${quiet[@]}"
