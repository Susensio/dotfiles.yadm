#!/usr/bin/env bash
# Wire the pi patch library and the extension bundler into pi's npm project and
# apply both. pi owns that package.json and yadm does not track it, so the hook
# line is injected here rather than versioned.
# The project is created when pi has not run yet, so pi's first-start
# auto-install of the packages in settings.json already carries the hook and
# applies it in that same start. After that the npm postinstall covers
# `pi install`/`pi update --extensions`. ADR-0066, ADR-0067.
#
# Order matters: patches re-apply first so a bundle built afterwards carries
# whatever they changed.
set -euo pipefail

agent_dir=${PI_CODING_AGENT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pi/agent}
project=$agent_dir/npm/package.json
library=$agent_dir/patches
bundler=$agent_dir/bundler

# Build the hook from whichever halves are present, so a checkout with only one
# of them still installs cleanly.
parts=()
[[ -f $library/reapply-all.sh ]] && parts+=("sh \"$library/reapply-all.sh\"")
[[ -f $bundler/run.sh ]] && parts+=("sh \"$bundler/run.sh\"")
[[ ${#parts[@]} -gt 0 ]] || exit 0
hook=""
for part in "${parts[@]}"; do
  hook=${hook:+$hook && }$part
done

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
  # printf as well as log: the bootstrap puts ~/bin on PATH, a hand-run may not,
  # and failing after the work is done would abort the whole bootstrap.
  if command -v log >/dev/null 2>&1; then
    log info "Wired the pi patch reapply and bundler into ${project/#"$HOME"/\~}"
  else
    printf '%s\n' "Wired the pi patch reapply and bundler into ${project/#"$HOME"/\~}"
  fi
fi

# Same order as the hook, and guarded the same way: a checkout carrying only one
# half must not abort the bootstrap on a missing file.
[[ -f $library/reapply-all.sh ]] && "$library/reapply-all.sh"
[[ -f $bundler/run.sh ]] && "$bundler/run.sh"
exit 0
