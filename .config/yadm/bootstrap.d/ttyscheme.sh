#!/usr/bin/env bash
# Upstream has no tags, so this fetch stands in for a tools.toml declaration
# until the aqua package lands (docs/BACKLOG.md).
set -euo pipefail

BIN_DIR=${XDG_BIN_HOME:-$HOME/.local/bin}
LIB_DIR=${XDG_LIB_HOME:-$HOME/.local/lib}
mkdir --parents "$BIN_DIR" "$LIB_DIR"

target=$LIB_DIR/ttyscheme
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

curl --fail --silent --show-error --location \
    https://raw.githubusercontent.com/kolunmi/ttyscheme/main/ttyscheme --output "$tmp"

# A rerun changes nothing: install only when upstream's script moved
if [[ -f $target ]] && cmp --silent "$tmp" "$target"; then
    exit 0
fi

chmod 755 "$tmp"
mv "$tmp" "$target"
ln -sfn "$target" "$BIN_DIR/ttyscheme"
