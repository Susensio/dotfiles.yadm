#!/usr/bin/env bash
# Dictation backend. The package is mise's (mise/conf.d/omarchy.toml##distro.omarchy);
# pacman does not run Superwhisper's per-user setup (service, preferences, panel and
# skill links), so the Omarchy installer does it once, unattended, where it never ran.
set -euo pipefail

command -v superwhisper &>/dev/null || exit 0
# Headless runs (omarchy update over SSH) have no user manager.
systemctl --user show-environment &>/dev/null || exit 0

if ! systemctl --user is-enabled --quiet superwhisper.service; then
  omarchy-install-dictation-superwhisper --background
  log success "superwhisper set up"
fi
