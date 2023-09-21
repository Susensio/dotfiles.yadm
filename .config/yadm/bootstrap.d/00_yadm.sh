#!/usr/bin/env bash

repo=https://github.com/TheLocehiliosan/yadm.git
folder="${HOME}/.local/lib/yadm"
symlink="${HOME}/.local/bin/yadm"
usermanpages="${XDG_DATA_HOME:-${HOME}/.local/share}/man/man1"

if [[ ! -d $folder ]]; then
  echo "Downloading latest yadm..." >&2
  git clone "${repo}" "${folder}"

  echo "Creating yadm symlink..." >&2
  ln -sfv "$(realpath ${folder}/yadm)" "${symlink}"

  echo "Updating manpages..." >&2
  ln -svf "$(realpath ${folder}/yadm.1)" "${usermanpages}/yadm.1"
fi
