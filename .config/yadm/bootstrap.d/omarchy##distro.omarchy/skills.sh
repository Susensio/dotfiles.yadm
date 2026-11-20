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

# Unlink only skill links targeting a given root, then remove every directory
# that left empty up to $HOME. A real directory, or a link to anywhere else, is
# someone else's and stays. "Someone else" includes another vendor: only the
# roots each vendor actually writes are passed here.
drop_skill_links() {
  local dir=$1 root=$2 entry parent
  [[ -d $dir ]] || return 0
  for entry in "$dir"/*; do
    [[ -L $entry ]] || continue
    [[ $(readlink -f -- "$entry") == "$root"/* ]] || continue
    printf 'Removing superseded skill link: %s\n' "$entry" >&2
    rm -- "$entry"
  done
  parent=$dir
  while [[ $parent == "$HOME"/* && $parent != "$HOME" ]]; do
    rmdir -- "$parent" 2>/dev/null || break
    parent=$(dirname -- "$parent")
  done
}

# Vendors whose installers link skills into the same $HOME roots Omarchy uses
# (ADR-0068 Corrections): name|skills root the vendor writes
vendors=("superwhisper|/opt/superwhisper/assets/agent-skill")

for spec in "${agents[@]}"; do
  IFS='|' read -r agent home_root xdg_sub var <<<"$spec"

  if [[ -n $home_root && -n ${!var:-} ]]; then
    drop_skill_links "$HOME/$home_root/skills" "$skills_root"
  fi

  command -v "$agent" &>/dev/null || continue
  destination=${!var:-$config_home/$xdg_sub}/skills
  mkdir -p "$destination"
  link_skills() {
    local root=$1 skill target
    for skill in "$root"/*/; do
      [[ -d $skill ]] || continue
      skill=${skill%/}
      target=$destination/${skill##*/}
      if [[ -e $target && ! -L $target ]]; then
        printf 'Skipping existing skill directory: %s\n' "$target" >&2
        continue
      fi
      ln -sfn "$skill" "$target"
    done
  }
  link_skills "$skills_root"
  # A vendor's skill rehomes the same way, into the same destination, because
  # its installer writes only $HOME roots and the $HOME copy disappears above.
  for vendor in "${vendors[@]}"; do
    IFS='|' read -r _ vroot <<<"$vendor"
    link_skills "$vroot"
  done
done

# The generic .agents convention has no agent binary and no config-dir variable
# of its own, and this layout's generic location is $XDG_CONFIG_HOME/.agents
# (mise/tasks/herdr-integrations writes it), so the $HOME one is always
# Omarchy's to remove.
drop_skill_links "$HOME/.agents/skills" "$skills_root"
for vendor in "${vendors[@]}"; do
  IFS='|' read -r _ vroot <<<"$vendor"
  drop_skill_links "$HOME/.agents/skills" "$vroot"
done

# Antigravity is not kept (ADR-0068) and exposes no redirect variable, so its
# root gets the generic-.agents treatment: Omarchy's migrations recreate the
# links, and they are always removed.
drop_skill_links "$HOME/.gemini/config/skills" "$skills_root"

# Whatever still sits in a $HOME skill root after the drops is a writer this
# layout does not know (ADR-0068: nothing warned when one appeared). Only a
# warning, so it surfaces instead of silently accumulating; a writer is
# handled by adding it to the vendors or agents table, never here.
warn_roots=(".agents")
for spec in "${agents[@]}"; do
  IFS='|' read -r _ home_root _ _ <<<"$spec"
  [[ -n $home_root ]] && warn_roots+=("$home_root")
done
for home_root in "${warn_roots[@]}"; do
  dir=$HOME/$home_root/skills
  [[ -d $dir ]] || continue
  for entry in "$dir"/*; do
    [[ -e $entry || -L $entry ]] || continue
    printf 'Unknown skill remains in $HOME: %s\n' "$entry" >&2
  done
done
