#!/usr/bin/env bash
set -e

# Unset TMUX to avoid nesting issues
unset TMUX
unset TMUX_PANE

CMD="${1:-}"
SESSION_NAME="${2:-main}"

if [ -z "$CMD" ]; then
    # No command provided, let tmux launch the default shell
    exec tmux -L herdr_scratchpad new-session -A -s "$SESSION_NAME"
else
    # Command provided, run it in the session
    exec tmux -L herdr_scratchpad new-session -A -s "$SESSION_NAME" "$CMD"
fi
