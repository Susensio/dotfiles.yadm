#!/usr/bin/env bash
set -euo pipefail

# Plain git on yadm's repo: this may run from a remote yadm (bootstrap.yadm.io),
# before any local one is installed or on PATH
YADM_REPO=${XDG_DATA_HOME:-$HOME/.local/share}/yadm/repo.git
yadm_git() { git --git-dir="$YADM_REPO" --work-tree="$HOME" "$@"; }

# Version controlled gitconfig
yadm_git config include.path "${XDG_CONFIG_HOME:-${HOME}/.config}"/yadm/gitconfig
# Let plain git work inside .config, for tooling that shells out to it and
# cannot be told about yadm. Git refuses to track a path named .git, so this
# pointer cannot live in the repo and has to be recreated per machine.
CONFIG_GITFILE="${XDG_CONFIG_HOME:-${HOME}/.config}/.git"
if [[ ! -e $CONFIG_GITFILE ]]; then
  log info "Pointing .config/.git at the yadm repo..."
  printf 'gitdir: %s\n' "$YADM_REPO" >"$CONFIG_GITFILE"
fi
