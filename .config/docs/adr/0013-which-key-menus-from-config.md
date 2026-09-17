# ADR-0013: Build which-key menus from config order and list-keys truth

Status: Accepted
Date: 2026-08-06

## Context

Modal key tables ([ADR-0012](0012-modal-tmux-key-tables.md)) need a hint menu per table.
The `tmux-which-key` plugin was considered and rejected: it requires declaring every menu entry by hand in a separate file, so a binding can silently drift out of sync with its menu entry.

## Decision

`scripts/which-key` builds each menu from two sources instead of a hand-kept list: `conf.d/*.conf` supplies order and grouping (blank lines in the config become the rules between groups), `list-keys` supplies truth — a declared binding is shown only if it is bound, anything bound but undeclared is appended at the end.
Armed via an alias in `15_aliases.conf` using `run-shell -b -d $WK_DELAY`, so entering a chain costs one idle delay and cancelling is free.
Every failure path exits 0, since `run-shell` treats a nonzero exit as an error and a menu that failed to draw is not worth a nag.
Drawing, sizing and positioning are left to `display-menu`.
Requires tmux 3.7.

## Consequences

A menu entry cannot drift from what is bound.
Cost: correctness is coupled to config *text* formatting, which produced two real bugs — bundled short flags like `bind -rN "note"` were misparsed until parsing switched to `getopt`, and `%if`/`%else` branches were invisible to the parser.

## Corrections

2026-09-17: the `%if`/`%else` limitation above no longer holds.
`50_scratchpad.conf` grew a `bind` inside its `%if` guard, which reordered the prefix table's menu because both branches counted toward config order.
`scripts/which-key` now resolves each candidate line through `tmux source-file -nv`, tmux's own dry-run parser, so a branch that didn't run on the current server is invisible to order too — see `declared()`'s and `live_lines()`'s docstrings.

