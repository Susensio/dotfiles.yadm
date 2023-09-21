#!/usr/bin/env bash
set -eu -o pipefail

while IFS=\; read cmd repo; do
  if ! command -v "${cmd}" &> /dev/null; then
    echo "Installing repo for ${cmd}..."
    ~/bin/download-gh-release --repo "${repo}" --cmd "${cmd}"
  fi
done < <(cat $(compgen -G "$(dirname -- $0)/requirements*.gh"))
