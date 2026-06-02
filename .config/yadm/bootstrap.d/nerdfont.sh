#!/usr/bin/env bash
set -euo pipefail

source "${HOME}/bin/log"

if ! command -v fc-cache >/dev/null 2>&1; then
  log_debug "No GUI detected (fc-cache missing). Skipping font installation."
  exit 0
fi

FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/NerdFonts"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d"
VERSION_FILE="${FONT_DIR}/.version"

LATEST_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest"
DOWNLOAD_URL="${LATEST_URL}/download/NerdFontsSymbolsOnly.tar.xz"

# Follow redirect to get to tag version, this is way faster than Github API
remote_url=$(curl -sIL -o /dev/null -w '%{url_effective}' "$LATEST_URL")
remote_version=$(basename "$remote_url")

if [[ -f "$VERSION_FILE" ]]; then
  log_debug "Checking for Nerd Font updates..."

  if [[ "$(cat "$VERSION_FILE")" == "$remote_version" ]]; then
    log_debug "Nerd Fonts are up to date."
    exit 0
  fi
fi

temp_dir=$(mktemp --directory)
trap "rm -rf $temp_dir" EXIT

log_info "Installig Nerd Fonts Symbols..."
curl --fail --location --output "$temp_dir/symbols.tar.xz" "$DOWNLOAD_URL"

# Extract the tar.xz file directly into the temp folder
tar --extract --file "$temp_dir/symbols.tar.xz" --directory "$temp_dir"

mkdir --parents --verbose "$FONT_DIR" "$CONF_DIR"
cp --verbose "${temp_dir}"/*.ttf --target-directory "$FONT_DIR/"
cp --verbose "${temp_dir}"/*.conf --target-directory "$CONF_DIR/"

echo "$remote_version" > "$VERSION_FILE"
fc-cache --force --verbose
