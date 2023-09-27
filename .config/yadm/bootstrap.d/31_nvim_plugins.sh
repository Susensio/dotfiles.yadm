#!/usr/bin/env bash
source ~/.config/profile
echo "Updating nvim plugins..." >&2
nvim --headless "+Lazy! restore" +qa
