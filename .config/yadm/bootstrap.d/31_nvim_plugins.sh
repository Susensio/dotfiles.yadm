#!/usr/bin/env bash
CURRENT="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/yadm/lazy-lock.json"
# if lockfile has changed
if cmp --silent "$CURRENT" "$CACHE"; then
  [[ -n "${DEBUG-}" ]] && echo "All nvim plugins up to lockfile" >&2
  exit 0
fi

echo "Updating nvim plugins..." >&2
nvim --headless "+Lazy! restore" +qa && cp "$CURRENT" "$CACHE"

