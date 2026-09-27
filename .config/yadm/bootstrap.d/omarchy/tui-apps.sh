#!/usr/bin/env bash
# Terminal-UI launcher entries, installed through omarchy-tui-install and run
# after preinstalls.sh, whose omarchy-tui-remove-all would otherwise sweep them.
# Tmux and Herdr attach through the same commands omarchy-launch-terminal-{tmux,herdr}
# wrap; the TUI.tile app id keeps them tiled like any other window.
# tm is single-word, so the desktop entry needs no bash quoting wrapper;
# ~/bin is on the manager PATH via environment.d/11_path.conf.
set -euo pipefail

command -v omarchy-tui-install &>/dev/null || exit 0

APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
tui() { [[ -f $APPS/$1.desktop ]] || omarchy-tui-install "${@:2}"; }
tui "Disk Usage" "Disk Usage" 'bash -c "dua i /"' float disk-usage
tui "Tmux" "Tmux" tm tile utilities-terminal
tui "Herdr" "Herdr" herdr tile utilities-terminal
