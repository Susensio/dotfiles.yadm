# ADR-0002: Unset dynamic systemd overrides to keep environment.d authoritative

Status: Accepted
Date: 2026-06-02

## Context

`environment.d` ([ADR-0001](0001-centralize-environment-variables.md)) is meant to be the single source of truth, but systemd merges two layers: static (generators/`environment.d`) and dynamic (D-Bus overrides via `systemctl set-environment`, and the Xsession push at script 95).
The dynamic layer wins and pins variables in memory — it keeps masking `environment.d` edits even after `daemon-reload`, so editing a `.conf` file and reloading silently does nothing for any name that was ever pinned.

## Decision

Before every reload, unset the dynamic overrides for exactly the variable names `environment.d`'s generator owns, so the static layer is authoritative again.
`_env_unpin` runs the generator binary, extracts the key names, and `systemctl --user unset-environment`s them.
`env_reload` chains: unpin → `daemon-reload` → `_env_pull` → `_env_sync_tmux`.
The same unpin also runs at X11 session start via `/etc/X11/Xsession.d/96fix-env-precedence`.
`_env_sync_tmux` pushes the result to both the main tmux server and the `scratchpad` server, since those are long-lived and hold their own stale copy.

## Consequences

`environment.d` edits reliably take effect after `env_reload`, without a full relogin.
Trade-off: unsetting is blunt — it discards every dynamic value for generator-owned names, including ones legitimately set at runtime by something other than `environment.d`, not just the stale ones.

