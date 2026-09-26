# ADR-0058: Put Omarchy-session variables in uwsm/env.d instead of environment.d, and leave the session PATH to uwsm

Status: Accepted
Date: 2026-09-26

## Context

`OMARCHY_SCREENSHOT_DIR` first went into `environment.d/tools.conf`.
`environment.d` was shared with Mint and loaded by the user manager for every login, including SSH and TTY, where an Omarchy capture variable meant nothing.
Omarchy documented `~/.config/uwsm/env.d/` for its session overrides, and uwsm sourced only there when it started the graphical session.

Moving the session `PATH` order into `uwsm/env.d` as well was weighed, to strip the mise shims and put `~/bin/overrides` first.
It would not have held: Omarchy's Hyprland `envs.lua` rewrote `PATH` for everything Hyprland started, after uwsm, and `autostart.lua` imported that into the user manager.
That prepend was a leftover upstream, fixed by a PR and patched locally per [ADR-0057](0057-omarchy-bugfix-patch-steps.md), rather than overridden from our own Hyprland config.
Masking Omarchy's `10-omarchy` with a same-named user file was also weighed; uwsm sourced every file in every config directory, so a user file could add to it but never replace it.

## Decision

A variable that only means something in the Omarchy graphical session goes in a file under `uwsm/env.d/`, in shell syntax; everything else stays in `environment.d`.
The session `PATH` keeps the order `environment.d` gives it, behind whatever uwsm's `10-omarchy` adds; no layer after it reorders `PATH`.
How the layers stack is described in §8 of `environment-architecture.md`.

## Consequences

Mint, SSH and TTY sessions no longer carry Omarchy-only variables.
A `uwsm/env.d` change needs a relogin; `env_reload` never reads it.
Two files now hold environment, in two syntaxes, and the choice between them has to be made per variable.
The mise shims that `10-omarchy` prepends stay ahead of `~/bin/overrides`, against [ADR-0007](0007-link-mise-tools-into-xdg.md), until that is decided separately.
