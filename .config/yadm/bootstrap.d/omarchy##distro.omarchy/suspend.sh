#!/usr/bin/env bash
# The lid is logind's plain suspend and Omarchy ships no sleep.conf.d, so a long
# sleep on an s2idle-only machine drains the battery instead of hibernating.
set -euo pipefail

# Hibernation is provisioned per machine, and only then can it end a sleep
command -v omarchy-hibernation-available &>/dev/null || exit 0
omarchy-hibernation-available || exit 0

# s2idle needs the ACPI RTC alarm to wake for the hibernate phase; hibernation setup adds it
if grep -q s2idle /sys/power/mem_sleep 2>/dev/null && ! grep -q rtc_cmos.use_acpi_alarm=1 /proc/cmdline; then
  log warn "No rtc_cmos.use_acpi_alarm=1 in the kernel cmdline; the hibernate phase may not fire"
fi

ASSETS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")/assets

# systemd-sleep reads sleep.conf on every invocation, so only logind needs the reload
SLEEP_CONF=/etc/systemd/sleep.conf.d/50-suspend-then-hibernate.conf
cmp -s "$ASSETS_DIR/suspend-then-hibernate.conf" "$SLEEP_CONF" ||
  sudo install -Dv --mode=644 "$ASSETS_DIR/suspend-then-hibernate.conf" "$SLEEP_CONF"

LID_CONF=/etc/systemd/logind.conf.d/50-lid-sleep.conf
if ! cmp -s "$ASSETS_DIR/lid-sleep.conf" "$LID_CONF"; then
  sudo install -Dv --mode=644 "$ASSETS_DIR/lid-sleep.conf" "$LID_CONF"
  sudo systemctl reload systemd-logind
fi
