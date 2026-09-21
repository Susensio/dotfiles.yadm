#!/usr/bin/env bash
set -eu
exec > /home/susensio/.config/herdr/smart-split.log 2>&1

# `type = "shell"` keybinds run detached and don't inherit $HERDR_PANE_ID,
# so --current (which resolves via that var) fails here; use
# $HERDR_ACTIVE_PANE_ID, which Herdr sets for detached shell keybinds instead.
read -r W H <<< "$(herdr pane layout --pane "$HERDR_ACTIVE_PANE_ID" | jq -r '.result.layout.panes[] | select(.focused) | "\(.rect.width) \(.rect.height)"')"

# Split right if it's wide, down if it's tall
if (( W * 10 >= H * 22 )); then
    herdr pane split --pane "$HERDR_ACTIVE_PANE_ID" --direction right --focus
else
    herdr pane split --pane "$HERDR_ACTIVE_PANE_ID" --direction down --focus
fi
