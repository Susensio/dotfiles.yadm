#!/usr/bin/env bash
set -euo pipefail

omarchy_path=${OMARCHY_PATH:-/usr/share/omarchy}
[[ -f $omarchy_path/install/user/mise-work.sh ]] || exit 0

work=$HOME/Work
[[ -d $work && ! -L $work ]] || exit 0

shopt -s nullglob dotglob
entries=("$work"/*)
if ((${#entries[@]} == 0)); then
  rmdir -- "$work"
  exit 0
fi

[[ ${#entries[@]} == 2 && ${entries[0]} == "$work/.mise.toml" && ${entries[1]} == "$work/tries" ]] || exit 0
[[ -f $work/.mise.toml && ! -L $work/.mise.toml ]] || exit 0
[[ -d $work/tries && ! -L $work/tries ]] || exit 0
[[ -z $(find "$work/tries" -mindepth 1 -print -quit) ]] || exit 0
printf '[env]\n_.path = "{{ cwd }}/bin"\n' | cmp -s - "$work/.mise.toml" || exit 0

rmdir -- "$work/tries"
rm -- "$work/.mise.toml"
rmdir -- "$work"
