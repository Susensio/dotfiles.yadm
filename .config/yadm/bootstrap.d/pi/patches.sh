#!/usr/bin/env bash
# Wire the pi patch library into pi's npm project and apply it. pi owns that
# package.json and yadm does not track it, so the hook line is injected here
# rather than versioned.
# The project is created when pi has not run yet, so pi's first-start
# auto-install of the packages in settings.json already carries the hook and
# applies the patch in that same start. After that the npm postinstall covers
# `pi install`/`pi update --extensions`. ADR-0066.
set -euo pipefail

agent_dir=${PI_CODING_AGENT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pi/agent}
project=$agent_dir/npm/package.json
library=$agent_dir/patches
[[ -f $library/reapply-all.sh ]] || exit 0

hook="sh \"$library/reapply-all.sh\""
current=$([[ -f $project ]] && jq -r '.scripts.postinstall // ""' "$project" || echo "")

if [[ $current != "$hook" ]]; then
  mkdir -p "$(dirname "$project")"
  tmp=$(mktemp "$project.XXXXXX")
  trap 'rm -f "$tmp"' EXIT
  if [[ -f $project ]]; then
    jq --arg hook "$hook" '.scripts.postinstall = $hook' "$project" > "$tmp"
  else
    jq -n --arg hook "$hook" \
      '{name: "pi-extensions", private: true, scripts: {postinstall: $hook}}' > "$tmp"
  fi
  mv "$tmp" "$project"
  log info "Wired the pi patch reapply into ${project/#"$HOME"/\~}"
fi

"$library/reapply-all.sh"
