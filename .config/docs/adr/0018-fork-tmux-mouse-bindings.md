# ADR-0018: Fork tmux default mouse bindings into conf.d

Status: Accepted
Date: 2026-06-02

## Context

Several stock tmux mouse behaviors needed fixing (menu-close-on-open timing, inconsistent swap keys, no clipboard-primary paste) and one needed adding (status-line right-click menus, which tmux ships no default for at all).
Layering deltas on top of the built-in bindings would leave the actual mouse behavior split between defaults invisible in this repo and overrides scattered around them.

## Decision

`conf.d/22_mouse.conf` copies tmux's own default mouse bindings in verbatim, headed `# DEFAULT mouse keybinds`, then fixes specific ones in place.
Menus bind on `MouseUp3` rather than `MouseDown3`: opening on MouseDown means that click's own MouseUp immediately follows, tmux never associates the two, and `-O` fails to save the menu so it closes at once.
`h`/`l` are swapped for consistency with the rest of the config, keeping `r` for Rename (stock tmux itself is inconsistent, using `n` in one menu and `r` in another).
Also layered on: primary-selection middle-click paste, drag-to-copy, clickable `[z]`/`[x]` pane-border buttons via `range=control|N` (zoom rendered only when it wouldn't be a no-op), and wheel-scroll into copy-mode except inside fullscreen apps, which pass through.

## Consequences

Every mouse behavior — stock and fixed — lives in one editable, visible file, and the status-line context menus exist where before there were none.
The real cost: this is a fork, not a diff.
Any change tmux makes to its own default mouse bindings has to be noticed, re-diffed, and merged in by hand; nothing here tracks upstream automatically.
