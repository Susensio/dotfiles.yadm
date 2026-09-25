# ADR-0051: Keep uwsm editor launcher on Omarchy instead of overriding it from tools.conf

Status: Accepted
Date: 2026-09-25

## Context

[ADR-0047](0047-helix-canonical-editor-name.md) made `environment.d/tools.conf` the tracked terminal-editor choice and had Omarchy's menu keep it in sync, but left precedence against uwsm's `EDITOR=omarchy-launch-editor --inline` open.
[ADR-0050](0050-unpin-x11-at-session-start.md) then stopped `env_reload` from clearing uwsm's override.
On Omarchy, the launcher reads the menu choice when invoked, while the tracked `EDITOR` line supplies the static value for other distros and expands into `SUDO_EDITOR` for `sudoedit`.
Overriding uwsm's `EDITOR` with the literal value from `tools.conf` would require another live manager update after each menu change, or a session restart.
Replacing the tracked value with the launcher would make the shared config depend on an Omarchy command unavailable elsewhere.

## Decision

Keep uwsm's `omarchy-launch-editor --inline` as the effective `EDITOR` while its Omarchy session is active.
Keep the terminal editor selected in Omarchy's menu in `environment.d/tools.conf`, as ADR-0047 specifies.
Its `SUDO_EDITOR="env $EDITOR"` expands from that static value, so `sudoedit` follows the selected terminal editor after the sync and environment reload.
`env_reload` preserves uwsm's launcher override, as ADR-0050 specifies.

## Consequences

Omarchy's `$EDITOR` follows later menu changes without rewriting the live session environment.
On other distros, `$EDITOR` remains the literal editor from `tools.conf`.
The systemd user manager is shared, so a login shell reached through SSH while uwsm is active can also receive the launcher through `_env_pull`.
The strings in `EDITOR` and `SUDO_EDITOR` differ on Omarchy, but terminal-editor menu choices lead to the same editor.
GUI-editor choices still leave `tools.conf` and `SUDO_EDITOR` at the previous terminal editor; the menu sync deliberately filters those choices, and support for them remains open.
The Omarchy behavior still needs a live first-run check.
