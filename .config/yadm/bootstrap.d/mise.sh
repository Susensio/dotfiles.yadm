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
mkdir --parents --verbose "$FISH_COMPLETIONS_DIR" &&
  mise completion fish >"$FISH_COMPLETIONS_DIR/mise.fish"

# mise exec supplies argc before tool dispatches its bootstrap command.
log info "Installing tools..."
mise exec argc -- "$HOME/bin/tool" bootstrap
