# Proposal: suspend an idle laptop on battery

Status: drafted 2026-11-20 from the BACKLOG entry, not built; shares the idle subsystem and the upstream blocker with the idle-dimming entry, which stays in BACKLOG because its local half needs no decision (wluma's own stage is simply disabled).

## Problem

Nothing suspends an idle laptop, so a lock screen left for 2h on battery (2026-10-20, 13:11 to 14:54) kept the machine awake, against ≤0.5%/h in s2idle (the full-night measurement under the TPM2 entry: 63% → 60% across 6h40m, 5h00m of it s2idle, 1h38m powered off).

Omarchy 4.0.4 has no such stage: `idle` in `shell.json` holds only `screensaver` and `lock` (`shell/README.md:237-282`), logind has no `IdleAction`, and `hypridle` is not installed.
The v3.0.0 `hypridle.conf` never suspended either: screensaver, lock and DPMS off only.

## Chosen shape

`hypridle` declared in `mise/conf.d/omarchy.toml##distro.omarchy`, a tracked `hypr/hypridle.conf` with one listener (`timeout = 1200`, `on-timeout = grep -qx 0 /sys/class/power_supply/AC*/online && systemctl suspend-then-hibernate`), `hypridle.service` enabled by a silent idempotent bootstrap step like `wluma.sh`, and an ADR; `omarchy-sleep-lock.service` still locks before the suspend (ADR-0069).
It shares the Wayland idle protocol with the shell's idle service, so neither disturbs the other's timers.

## Alternatives weighed

- logind `IdleAction=suspend-then-hibernate` in `logind.conf.d` needs no package but never fires, since nothing in this Hyprland session sets the session `IdleHint`.
- `swayidle` has the same shape as `hypridle` but is not Hyprland-native.
- A user timer or script after the lock is the handmade version the inline AC check avoids.
- Patching the shell's `idle/Service.qml` is a package file, so it would need a `bootstrap.d/omarchy/bugfix/` step (ADR-0057) and a suspend stage upstream lacks.
- Omitting the AC check is plainer but also suspends on AC.

A DPMS-off stage is left out on purpose: the screen-on bug was the missing `en_GB` locale, fixed by `bootstrap.d/12_locale.sh`.
For the record, the root cause of the lit lock screen found on the way: `omarchy-shell` printed Qt's `Detected locale "C"` warning to stdout while `en_GB` was ungenerated, so the idle service's `[[ $(omarchy-shell lock isLocked) == "true" ]]` guard failed, the screensaver launched over the lock, its window closing cancelled the cycle, and `omarchy-system-wake` lit the display with no re-blank (`lock/Service.qml:171`).
