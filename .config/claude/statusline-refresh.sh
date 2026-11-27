#!/bin/sh
# Claude Code statusline entry, re-run every second by refreshInterval so a sudo popup shows within a tick.
# Prints herdr's waiting marker while asroot's popup is open for this pane (docs/adr/0139-asroot-popup-marks-agent-waiting.md),
# then statusline.sh's line, which reruns only when the input changed: a tick changes only total_duration_ms.

run="${XDG_RUNTIME_DIR:-/tmp}"
input=$(cat)

if [ -n "${HERDR_PANE_ID:-}" ] && read -r pid 2>/dev/null <"$run/asroot-waiting/$HERDR_PANE_ID" &&
  kill -0 "$pid" 2>/dev/null; then
  # herdr's asroot_sudo_popup rule matches this text; keep the two in step.
  printf '\033[1;33m🔑 asroot: password in the sudo popup\033[0m\n'
fi

sid=$(printf '%s' "$input" | sed -n 's/^{"session_id":"\([^"]*\)".*/\1/p')
cache="$run/claude-statusline/${sid:-default}"
key=$(printf '%s' "$input" | sed 's/"total_duration_ms":[0-9]*//')
if [ -f "$cache.out" ] && [ "$key" = "$(cat "$cache.in" 2>/dev/null)" ]; then
  cat "$cache.out"
  exit 0
fi
mkdir -p "${cache%/*}"
out=$(printf '%s' "$input" | sh "$(dirname "$0")/statusline.sh") || exit
printf '%s\n' "$out" >"$cache.out"
printf '%s' "$key" >"$cache.in"
printf '%s\n' "$out"
