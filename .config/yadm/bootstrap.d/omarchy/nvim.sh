#!/usr/bin/env bash
# ~/.config/nvim is ours, but Omarchy's omarchy-nvim seeds a LazyVim starter
# into it from /etc/skel, and its migrations write into lua/config/. Our
# init.lua loads none of it, so whatever yadm does not track there is removed.
set -euo pipefail

[[ -d /usr/share/omarchy-nvim ]] || exit 0

YADM_REPO=${XDG_DATA_HOME:-$HOME/.local/share}/yadm/repo.git
NVIM_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/nvim
[[ -d $NVIM_DIR ]] || exit 0

# Paths relative to $HOME; --others without --exclude-standard, so the
# starter's own .gitignore hides nothing
readarray -t -d '' foreign < <(
  git -C "$HOME" --git-dir="$YADM_REPO" --work-tree="$HOME" \
    ls-files -z --others -- "$NVIM_DIR"
)
((${#foreign[@]})) || exit 0

log info "Removing Omarchy's LazyVim starter from $NVIM_DIR..."
(cd "$HOME" && rm -- "${foreign[@]}")
find "$NVIM_DIR" -mindepth 1 -type d -empty -delete
