#!/usr/bin/env bash
set -euo pipefail

if command -v apt-get &>/dev/null && ! grep -rq "mise" /etc/apt/sources.list*; then
  log info "Adding mise repository..."
  pkg-install extrepo
  sudo extrepo enable mise
fi


if ! command -v mise &>/dev/null; then
  log info "Installing mise..."
  pkg-install mise
  log info "mise installed"
fi

# Integrate with fish. User vendor dir, so it never overwrites a packaged copy.
FISH_COMPLETIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fish/vendor_completions.d"
mkdir --parents "$FISH_COMPLETIONS_DIR"
completion=$(mise completion fish)
[[ -f $FISH_COMPLETIONS_DIR/mise.fish && $(<"$FISH_COMPLETIONS_DIR/mise.fish") == "$completion" ]] ||
  printf '%s\n' "$completion" >"$FISH_COMPLETIONS_DIR/mise.fish"

# Machine-wide: every [bootstrap.packages] entry mise loads, not only tool's files.
# services carries the tool-update unit that `auto_update` relies on (ADR-0007).
# Each part runs only when its own status says something differs: a pass that changes
# nothing still costs seconds and runs its hooks, and the status checks are cheap or,
# for packages, cheaper. `ls --missing` lists tools to install and prints nothing otherwise.
parts=()
# The bootstrap pipes stderr through tee, and mise refuses to ask for a sudo password
# unless stderr is a terminal, so cache it first.
if ! mise bootstrap packages status --missing &>/dev/null; then
  sudo -v
  parts+=(packages)
fi
[[ -n $(mise ls --global --missing 2>/dev/null) ]] && parts+=(tools)
# A container has no systemd to hold services
if [[ -d /run/systemd/system ]] && ! mise bootstrap services status --missing &>/dev/null; then
  parts+=(services)
fi
((${#parts[@]})) || exit 0

only=$(IFS=,; echo "${parts[*]}")

# The status checks named the parts; say what is coming before the quiet minutes.
# `ls --missing` names the tools; `packages status` would name packages too, but
# counting them here would run the check twice, so the part's own line stays generic.
tools=$(mise ls --global --missing --json 2>/dev/null | jq -r 'keys_unsorted | join(", ")')
if [[ -n $tools ]]; then
  log info "mise: installing ${tools}"
fi
for part in "${parts[@]}"; do
  case $part in
    packages) log info "mise: installing every [bootstrap.packages] entry" ;;
    services) log info "mise: applying services" ;;
  esac
done

# --quiet hides the 3-second progress-bar frames mise re-renders line by line when
# stderr is not a tty (the bootstrap pipes it through tee); DEBUG drops the filter to
# watch the downloads and hooks instead.
quiet=(--quiet)
[[ -n ${DEBUG:-} ]] && quiet=()

mise bootstrap --only "$only" --yes "${quiet[@]}"
log info "mise bootstrap done (${only})"
