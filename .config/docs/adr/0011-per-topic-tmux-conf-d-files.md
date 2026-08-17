# ADR-0011: Give each tmux topic its own conf.d file and keep logic in scripts

Status: Accepted
Date: 2026-08-07

## Context

With `tmux.conf` glob-sourcing `conf.d/*.conf`
([ADR-0010](0010-self-locating-tmux-conf.md)), a
growing set of options, bindings and hooks needed a rule for where to land,
or unrelated settings pile into whatever file is already open.

## Decision

Each discrete topic gets its own file in `conf.d/`: `00_reset`, `10_main`,
`15_aliases`, `20_navigation`, `21_copy`, `22_mouse`, `30_gruvbox`,
`31_visual`, `50_scratchpad`, `90_plugins`, `99_tpm`. The numeric prefix
fixes source order. Non-trivial logic goes in `scripts/`, not inline in a
`.conf` file. As part of this pass, `20_copy.conf`/`20_mouse.conf` were
renumbered to `21_`/`22_` to make their dependency on `20_navigation.conf`'s
load order explicit.

## Consequences

A given concern is easy to find and touch in isolation, and the prefix
communicates dependency order at a glance. Costs: ordering is implicit in
the filename and breaks silently on a careless rename. Cross-file
dependencies are real and sharp — an alias defined in `15_aliases.conf`
is not yet registered when `20_navigation.conf` is parsed, which forces
`\;` instead of `{ }` in bindings that use it (see the comments in
`20_navigation.conf` and `22_mouse.conf`). `00_reset.conf` must run first
since it wipes bindings/aliases; `99_tpm.conf` must run last. Pushing logic
into `scripts/` also adds a subprocess per keystroke for anything that uses
it.
