# ADR-0012: Replace the flat tmux prefix map with modal key tables

Status: Accepted
Date: 2026-08-06

## Context

The prefix map had grown into a flat list of one-key-does-one-thing
bindings. That does not scale and is not discoverable, and gives a
which-key style hint menu ([ADR-0013](0013-which-key-menus-from-config.md))
nothing to group by.

## Decision

Bindings are split into modal key tables — `prefix`, `pane`, `tab`,
`session`, `config` — entered explicitly via `switch-client -T`.
`prefix` is set to `None` in `10_main.conf` so tmux never auto-enters the
prefix table; `C-Space` is bound in `root` instead, and its command both
enters the table and arms its which-key menu, the same way every other
table does.

## Consequences

Related actions are grouped, discoverable via the menu, and the README's
`p`/`t`/`s`/`c` branching maps directly onto table names. Costs: `prefix
None` gives up tmux's built-in prefix handling — `send-prefix` and the usual
double-tap-prefix idiom for nested sessions no longer work. Every table has
to arm its own which-key explicitly; there is no default. A key moved
between tables keeps responding from its old table until the server
restarts, which is exactly why `00_reset.conf` loops over `list-keys`
output to unbind every custom table before re-sourcing — `unbind -a -T`
errors on a table that does not exist yet, so a static unbind list would
not do it.
