# ADR-0091: Set LC_TIME to a Monday-first locale through environment.d, instead of the clock's weekStartDay or a system locale

Status: Accepted
Date: 2026-10-20

## Context

The Omarchy clock's calendar opened on Sunday, and the panel offered three ways out.
Its `weekStartDay` setting overrides the week start for that widget alone, written into `omarchy/shell.json`.
`Panel.qml` otherwise falls back to `Qt.locale().firstDayOfWeek`, so a Monday-first locale fixes it too.
Fixing the locale also moves every other date on the machine, which the widget setting leaves alone.

The locale was `en_US.UTF-8` and the calendar really did read Sunday from it: glibc's `en_US` defines no `first_weekday`, so POSIX defaults it to 1 (Sunday), and Qt's ICU path agreed.
Only `en_US` was generated in `/usr/lib/locale/locale-archive`, so `en_GB` existed as a name but not as data, and exporting it without `locale-gen` made glibc consumers fall back to `C` with a warning.

Three homes were weighed.
`/etc/locale.conf` through `localectl` is system-wide and root-owned, so it would not travel with yadm.
`hypr/envs.lua` only reaches the Omarchy session, and by the layering in `environment-architecture.md` §8 an `hl.env` there wins over the layers below.
`environment.d` is the user manager's static base, inherited by Hyprland, the shells that pull from it, and SSH or TTY logins alike (ADR-0058).
`~/.config/locale.conf` was rejected as a name: Arch's `/etc/profile.d/locale.sh` sources it *instead of* `/etc/locale.conf`, so a file holding only `LC_TIME` would shadow `LANG` for login shells.

## Decision

`environment.d/12_locale.conf` sets `LC_TIME=en_GB.UTF-8` and leaves `LANG` at `en_US.UTF-8`, so messages stay English while dates, day and month names, and the week start follow a Monday-first locale.
The bootstrap step `bootstrap.d/12_locale.sh` enables `en_GB.UTF-8` in `/etc/locale.gen` and runs `locale-gen` when the locale is missing, since the generation is root-owned and cannot be tracked.

## Consequences

One variable now covers the calendar and every other `LC_TIME` consumer: `ls -l`, `git log`, and `date +%x` render day-first, and the clock shows Sunday as the week's last day.
`LC_TIME` is inherited from the user manager, so it applies from the next login; a shell that pulls from the manager through `_env_pull` sees it sooner.
The setting depends on `environment.d` being loaded at all: a process started without `XDG_RUNTIME_DIR`, such as under `env -i`, falls back to `en_US` and Sunday.
The step rewrites `/etc/locale.gen` and then runs `locale-gen`, which rebuilds the whole locale archive rather than adding one entry, so it happens once per machine and only while the locale is still missing.
An Omarchy update that resets `locale.gen` to its package state is repaired on the next bootstrap.
The clock's own `weekStartDay` stays unset on purpose: setting it would mask the locale and hide a broken `environment.d` from the calendar that depends on it.

## Corrections

2026-11-06: the Consequences said the clock's calendar followed `LC_TIME` and that its `weekStartDay` stayed unset on purpose.
Omarchy 4.5.0 moved the calendar's default week start to the display language's `formatLocale` (`en` → `en-US`), so it opened on Sunday again with `LC_TIME=en_GB.UTF-8` still in force; [ADR-0108](0108-omarchy-clock-week-start.md) pins `weekStartDay` instead.
The `LC_TIME` decision above stands for shell dates, and only the calendar claim is superseded.
