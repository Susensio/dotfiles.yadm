# ADR-0014: Keep both vim and helix copy-mode grammars

Status: Accepted
Date: 2026-08-08

## Context

Since Helix replaced Neovim ([ADR-0008](0008-replace-neovim-with-helix.md)), copy-mode muscle memory is split.
tmux's native `copy-mode-vi` behaves like vim: `v` opens Visual mode, all following motions extend.
Helix's `w`/`b`/`e` *replace* the selection by default and only extend once `v` toggles select-mode on.
Same keys, opposite behavior on the first press — not a keymap difference, a grammar difference.
`docs/vim-vs-helix-motions.md` documented both models as the shared reference for auditing this file, and was deleted.

## Decision

Keep both grammars, switched by `@copy_profile` (`vim` or `helix`), default `helix`.
Everything after the profile `%if`/`%else` block in `conf.d/21_copy.conf` is shared.
The helix branch needs a synthetic per-pane `@copy_select` flag to track select-mode, reset on every fresh entry into copy-mode via a `pane-mode-changed` hook — `y` and mouse-drag-end exit copy-mode through `copy-pipe-and-cancel` without ever reaching the Escape binding that would otherwise clear it. Escape is itself per-profile: helix exits copy-mode outright and only swallows the key while the flag is set, to fall back to normal mode, whereas vim clears a live selection first.

## Consequences

Either grammar is available on demand, matching whichever editor's muscle memory is active, and the profile split gives future audits (like the one that produced the reference doc) a single place to check for paradigm leakage.
Costs: roughly 35 lines of `%if`/`%else` plus separate text-object tables per profile — a helix-only config would be far smaller, a vim-only one smaller still.
The `@copy_select` flag is extra state living outside tmux's own selection tracking, and its reset-on-entry hook is a subtle-bug surface if a new exit path is ever added without updating it.

## Corrections

2026-08-26: the line above was written in the present tense, naming `docs/vim-vs-helix-motions.md` as the shared reference for auditing the copy-mode config.
That document was deleted, and the tracked `tmux-config` skill neither carries it in its references nor cites it, so git history holds the only copy under version control.
The line is now past tense, anchored to when it was true, where it cannot rot again.
