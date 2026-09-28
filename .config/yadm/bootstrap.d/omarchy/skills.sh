#!/usr/bin/env bash
set -euo pipefail

skills_root=${OMARCHY_PATH:-/usr/share/omarchy}/default/agents/skills
[[ -d $skills_root ]] || exit 0
skills_root=$(readlink -f -- "$skills_root")

config_home=${XDG_CONFIG_HOME:-$HOME/.config}

# Omarchy provisions its skills into $HOME-relative agent roots, from both its
# user provisioning and its update migrations. The tools that accept a
# config-dir variable are rehomed under $XDG_CONFIG_HOME, and their $HOME copy
# is superseded: it is removed only while that variable is set, because
# environment.d applies from login on and a pre-login run would otherwise strip
# the copy the tool can still reach (ADR-0068).
#
# agent|$HOME root Omarchy writes|XDG subpath|redirect variable
agents=(
  "claude|.claude|claude|CLAUDE_CONFIG_DIR"
  "codex|.codex|codex|CODEX_HOME"
  "pi|.pi/agent|pi/agent|PI_CODING_AGENT_DIR"
  "opencode||opencode|OPENCODE_CONFIG_DIR"
  "hermes|.hermes|hermes|HERMES_HOME"
)

# Unlink only Omarchy's own skill links, then remove every directory that left
# empty up to $HOME. A real directory, or a link to anywhere else, is someone
# else's and stays.
drop_omarchy_links() {
  local dir=$1 entry parent
  [[ -d $dir ]] || return 0
  for entry in "$dir"/*; do
    [[ -L $entry ]] || continue
    [[ $(readlink -f -- "$entry") == "$skills_root"/* ]] || continue
    printf 'Removing superseded skill link: %s\n' "$entry" >&2
    rm -- "$entry"
  done
  parent=$dir
  while [[ $parent == "$HOME"/* && $parent != "$HOME" ]]; do
    rmdir -- "$parent" 2>/dev/null || break
    parent=$(dirname -- "$parent")
  done
}

for spec in "${agents[@]}"; do
  IFS='|' read -r agent home_root xdg_sub var <<<"$spec"

  if [[ -n $home_root && -n ${!var:-} ]]; then
    drop_omarchy_links "$HOME/$home_root/skills"
  fi

  command -v "$agent" &>/dev/null || continue
  destination=${!var:-$config_home/$xdg_sub}/skills
  mkdir -p "$destination"
  for skill in "$skills_root"/*/; do
    [[ -d $skill ]] || continue
    skill=${skill%/}
    target=$destination/${skill##*/}
    if [[ -e $target && ! -L $target ]]; then
      printf 'Skipping existing skill directory: %s\n' "$target" >&2
      continue
    fi
    ln -sfn "$skill" "$target"
  done
done

# The generic .agents convention has no agent binary and no config-dir variable
# of its own, and this layout's generic location is $XDG_CONFIG_HOME/.agents
# (mise/tasks/herdr-integrations writes it), so the $HOME one is always
# Omarchy's to remove.
drop_omarchy_links "$HOME/.agents/skills"
