# ADR-0085: Keep the MX Keys backlight out of Omarchy's keyboard-backlight handling instead of adding a Solaar-backed hook

Status: Accepted
Date: 2026-10-05

## Context

The two Omarchy keyboard-backlight bugfix steps ([Omarchy PR #10364](https://github.com/omacom/omarchy/pull/10364) and [Omarchy PR #13729](https://github.com/omacom/omarchy/pull/13729)) save and restore the laptop keyboard backlight around screen blanking, hibernation and resume, and the local patches add a per-device runtime snapshot to `omarchy-brightness-keyboard`.
On this Dell XPS 13 the command finds only `dell::kbd_backlight`, and the machine also has a Logitech MX Keys on the Unifying receiver whose backlight showed the same symptom — dark with nothing to bring it back — which suggested the same fix might apply.
Investigation found a different mechanism.
The MX Keys backlight is driven entirely by the keyboard's firmware from its proximity and ambient-light sensors; the kernel's `hid-logitech-hidpp` and `hid-logitech-dj` drivers create no LED class device for it, so `/sys/class/leds/*kbd_backlight*` matches only `dell::kbd_backlight`.
The only userspace control is HID++ 2.0 feature `0x1982 BACKLIGHT2`, which Solaar exposes as an on/off/automatic setting; `logiops` defines the feature constants but implements no backlight.
Its own backlight keys do not reach userspace either: pressing them produces no event in `keyd monitor`, so they cannot be rebound the way Omarchy's `XF86KbdBrightness*` bindings are.
A gen1 MX Keys (product `0x408A`) reports `BACKLIGHT2` version 1, whose Solaar setting offers no numeric level or hands-in/out timeouts, only the mode.

Two alternatives were weighed.
Add a Solaar-backed hook beside the existing steps so blank and sleep also drive the MX Keys, matching the laptop's behaviour.
Or record that the existing handling is laptop-only and leave the MX Keys to its firmware.

## Decision

Omarchy's keyboard-backlight handling stays laptop-only.
The two bugfix steps keep acting on the first `/sys/class/leds/*kbd_backlight*` match, which is the Dell panel; they gain no MX Keys branch, no Solaar dependency and no new keybinding.
The MX Keys backlight is treated as firmware-owned and out of scope.

## Consequences

The blank/sleep off-and-restore covers exactly the device `omarchy-brightness-keyboard` can address, so an MX Keys that stays dark is not this command's doing and cannot be fixed here.
Lighting the MX Keys from the host would need a separate Solaar rule or `solaar config` call wired into `omarchy-system-wake` and the sleep hook, and on a version-1 keyboard it could only switch the backlight between on, off and automatic — a new concern rather than a re-use of the Dell path.
`docs/omarchy.md`'s patch list points at this record so the next reader does not re-open the same line of inquiry.

