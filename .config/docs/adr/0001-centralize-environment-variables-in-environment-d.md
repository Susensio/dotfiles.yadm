# ADR-0001: Centralize environment variables in environment.d

Status: Accepted
Date: 2026-06-02

## Context

Desktop login splits into two independent process trees: `systemd --user`
(background services) and LightDM/X11 (the GUI branch). A variable set in one
is not automatically visible to the other. Variables were previously set
piecemeal: `profile.d` scripts, and fish `conf.d` files (`00_profile.fish`,
`colors.fish`, `fzf.fish`) exporting vars at shell startup. That only reaches
shells launched after the edit, and never reaches `systemd --user` services or
the LightDM branch at all.

## Decision

Set all environment variables as static `KEY=VALUE` files under
`environment.d/` (`10_xdg.conf`, `11_path.conf`, `tools.conf`, `fzf.conf`,
`ls_colors.conf`), read by `systemd-environment-d-generator` at session start.
This becomes the single source of truth; see `ENVIRONMENT_ARCHITECTURE.md` §3.

## Consequences

Every process hierarchy — shells, systemd services, X11 apps — reads the same
values, once the generator has run, instead of each needing its own copy of
the logic. Trade-off: `environment.d` syntax is strictly static `KEY=VALUE`,
no shell logic, no command substitution, no conditionals, so anything dynamic
has to live elsewhere (fish functions, etc.). It's also inert until a reload
or relogin — generators only run at session start, not on file edit, which is
the problem [ADR-0002](0002-unset-dynamic-systemd-overrides-to-keep-environmen.md)
addresses.

