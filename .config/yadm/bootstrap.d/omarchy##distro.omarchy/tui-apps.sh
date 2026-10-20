#!/usr/bin/env bash
# Terminal-UI launcher entries, installed through omarchy-tui-install after
# preinstalls.sh, whose omarchy-tui-remove-all would otherwise sweep them.
# Entries older than this script (any edit here) are reinstalled; icons come
# from `icon`, whose result goes in the last argument.
set -euo pipefail

command -v omarchy-tui-install &>/dev/null || exit 0

APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
tui() {
  [[ $APPS/$1.desktop -nt ${BASH_SOURCE[0]} ]] && return
  OMARCHY_REMOVE_NOTIFY=false omarchy-tui-remove "$1" || true
  omarchy-tui-install "${@:2}"
}
tui "Disk Usage" "Disk Usage" 'bash -c "dua i /"' float disk-usage
tui "Claude Code" "Claude Code" claude tile https://cdn.jsdelivr.net/gh/selfhst/icons/png/claude.png
tui "Tmux" "Tmux" tm tile utilities-terminal
tui "Herdr" "Herdr" herdr tile utilities-terminal
