#!/usr/bin/env bash
# init.lua installs its plugins and parsers on start, and waits for them headless.
# Sorts after mise.sh, which installs nvim outside Arch.
set -euo pipefail

command -v nvim >/dev/null || exit 0

nvim --headless +qa
