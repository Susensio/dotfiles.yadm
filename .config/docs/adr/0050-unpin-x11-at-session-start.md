# ADR-0050: Unpin the X11 blanket import at session start instead of every environment reload

Status: Accepted
Date: 2026-09-25
Supersedes: [ADR-0002](0002-unset-systemd-overrides.md)

## Context

ADR-0002 cleared dynamic systemd user-manager overrides before every `env_reload`, because X11's `95dbus_update-activation-env` had copied the whole session environment over values from `environment.d`.
The following `96fix-env-precedence` script already cleared those overlapping names at X11 session startup through Mint's Bash LightDM wrapper, but the reload repeated the operation.
Omarchy 4.0.4's uwsm setup exported its changed session values, including `EDITOR` and `PATH`, into the same user manager.
The broad reload unpin removed those deliberate values too, even when invoked from an SSH shell while uwsm was active.
Branching on the calling shell's X11 or Wayland environment could not identify which session owned the user-manager values.
The X11 cleanup script also used Bash arrays although `/etc/X11/Xsession` could source it under `/bin/sh`; Mint's LightDM wrapper happened to source it under Bash.

## Decision

Keep the unpin immediately after X11's blanket import in `96fix-env-precedence`, and make that script valid for POSIX `sh` as well as Bash.
Its variable splitting runs in a subshell so it does not change Xsession's arguments or globbing setting.
Remove the repeated unpin from `env_reload` and delete its unused Fish helper.
The reload now reruns the environment generator, imports the resulting manager environment into the current shell, and syncs tmux.
Session-specific dynamic overrides remain in the manager.

## Consequences

On X11 setups that run the startup cleanup, later `environment.d` changes can be reloaded without clearing session values again.
On uwsm, a reload preserves the variables it exported, including `EDITOR` and `PATH`.
An `environment.d` edit to a name overridden later by another component stays masked until that component updates or removes its override; `env_reload` no longer claims ownership of every dynamic value.
The Omarchy behavior still needs a live first-run check.
