#!/usr/bin/env bash
# init.lua installs its plugins and parsers on start, and waits for them headless.
# Sorts after mise.sh, which installs nvim outside Arch.
set -euo pipefail

# Every machine declares nvim; its absence means the link was never made (system-install failed)
command -v nvim >/dev/null || {
  log warn "nvim is not on PATH, nvim plugins not installed: run mise run system-install"
  exit 0
}

nvim --headless +qa
