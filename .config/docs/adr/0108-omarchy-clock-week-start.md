# ADR-0108: Pin the clock's weekStartDay in shell.json, since Omarchy 4.5 takes the calendar's default week start from the display language

Status: Accepted
Date: 2026-11-06

## Context

[ADR-0091](0091-monday-first-lc-time.md) made dates follow `LC_TIME=en_GB.UTF-8` and deliberately left the clock's `weekStartDay` unset, so the calendar's week start would come from the locale and a broken `environment.d` would show there.

Omarchy 4.5.0 changed where that default comes from.
`plugins/panels/clock/Panel.qml` resolves it from `Qt.locale(Commons.I18n.formatLocale)`, and `Commons/I18n.qml` reads `formatLocale` out of `default/i18n/locales.json` for the display language in `~/.config/omarchy/language`, so names and the week start follow the shell's language rather than the system locale.
With no language file that is `en`, which the registry maps to `en-US`, whose first day is Sunday: the calendar opened on Sunday again while `LC_TIME=en_GB.UTF-8` was still set in the user manager and in the running `quickshell`.
The registry ships no Monday-first English language — English is only `en`/`en-US` — so no locale or language this machine can select moves the calendar's default any more.

Alternatives weighed: writing `~/.config/omarchy/language` cannot help for the same reason; editing `default/i18n/locales.json` is a package file and would need a `bootstrap.d/omarchy/bugfix/` step ([ADR-0057](0057-omarchy-bugfix-patch-steps.md)) to survive updates; leaving it to `environment.d` alone keeps the calendar on Sunday; the widget's own setting is written by its "W" heading anyway and lives in tracked `omarchy/shell.json`, which travels with yadm and needs no patch.

## Decision

`omarchy/shell.json` sets `"weekStartDay": "monday"` on the `omarchy.clock` bar entry, using the weekday names `Model.js` accepts and the panel's toggle writes.
The shell watches that file, so the change applies without a restart.
`environment.d/12_locale.conf` keeps `LC_TIME=en_GB.UTF-8` for shell dates — `ls -l`, `git log`, `date +%x` — and the bootstrap still generates the locale.

## Consequences

The calendar's week start no longer depends on the display language or on `LC_TIME`: neither a locale regression nor a language switch moves it, and the "W" heading still toggles it back into `shell.json`.
ADR-0091's claim that the calendar follows the locale is now false; its Corrections say so, and the locale stays a shell-date setting rather than the desktop's date convention.
A future Omarchy release that derives the default from something else would not move this calendar either, so a stale pin hides that change instead of failing visibly.
An upstream Monday-first English display language would make the pin redundant, not wrong.
