#!/usr/bin/env bash
set -euo pipefail

source "${HOME}/bin/log"

REPO=yadm-dev/yadm

BIN_HOME=${XDG_BIN_HOME:-$HOME/.local/bin}
LIB_HOME=${XDG_LIB_HOME:-$HOME/.local/lib}
MAN_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/man"
FISH_COMPLETIONS_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/fish/vendor_completions.d
mkdir --parents --verbose "$BIN_HOME" "$LIB_HOME" "$MAN_HOME/man1" "$FISH_COMPLETIONS_DIR"


if ! type -P yadm &> /dev/null; then
  if [[ ! -d ${LIB_HOME}/yadm ]]; then
    log_info "Fetching latest yadm release URL..."
    tarball_url=$(curl -s https://api.github.com/repos/${REPO}/tags | jq -r '.[0].tarball_url')

    log_info "Downloading and extracting yadm..."
    curl -sL "$tarball_url" | tar -xz -C "${LIB_HOME}/yadm" --strip-components=1
  fi

  log_info "Creating yadm symlink..."
  ln -srfv "$(realpath "${LIB_HOME}"/yadm/yadm)" "${BIN_HOME}/"

  log_info "Updating manpages..."
  ln -srfv "$(realpath "${LIB_HOME}"/yadm/yadm.1)" "${MAN_HOME}/man1/"

  log_info "Updating fish completions..."
  ln -srfv "$(realpath "${LIB_HOME}"/yadm/completion/fish/yadm.fish)" "$FISH_COMPLETIONS_DIR/"
fi

# Version controlled gitconfig
${BIN_HOME}/yadm gitconfig include.path "${XDG_CONFIG_HOME:-${HOME}/.config}"/yadm/gitconfig
# Do not pollute $HOME with github stuff
${BIN_HOME}/yadm -C $HOME sparse-checkout set --no-cone "/*" "!/README.md" "!/.github"

