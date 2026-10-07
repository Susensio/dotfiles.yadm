#!/usr/bin/env bash
# Sourcing tmux.conf runs tpack, which installs the declared plugins.
# Sorts after mise.sh, which installs tpack.
set -euo pipefail

command -v tmux >/dev/null || exit 0

socket=bootstrap-$$
trap 'tmux -L "$socket" kill-server 2>/dev/null' EXIT
TERM=${TERM:-xterm-256color} tmux -L "$socket" -f /dev/null new-session -d
tmux -L "$socket" source-file "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
