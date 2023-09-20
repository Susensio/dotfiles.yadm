#!/usr/bin/env bash
set -eu -o pipefail

while IFS=\; read cmd repo; do
  ~/bin/download-gh-release --repo "${repo}" --cmd "${cmd}"
done < requirements.gh
