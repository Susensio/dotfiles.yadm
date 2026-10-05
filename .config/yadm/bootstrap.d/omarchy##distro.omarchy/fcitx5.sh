#!/usr/bin/env bash
# fcitx5 only ran to resolve ~/.XCompose sequences, unreachable since Caps
# stopped being Multi_key; keyd's both-Shifts toggle owns Caps Lock now.
# The env vars come from environment.d/10-omarchy-fcitx.conf##distro.omarchy
# (a symlink to /dev/null), which materialises next to this step in the same
# alternate: keep or drop both together.
# Omarchy's migration 1785167800 re-enables the unit, so this re-disables it.
set -euo pipefail

systemctl --user disable --now omarchy-fcitx5.service >/dev/null 2>&1 || true
# A service with Restart=always is replaced by a stray autostart process on the
# next graphical login, and a second fcitx5 exits 0 on the bus name it owns.
pkill -x fcitx5 >/dev/null 2>&1 || true
