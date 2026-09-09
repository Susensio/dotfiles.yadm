# ADR-0042: Use one tmux-native copy mode instead of Vim and Helix profiles

Status: Accepted
Date: 2026-09-09
Supersedes: [ADR-0014](0014-keep-vim-and-helix-copy-mode.md)

## Context

ADR-0014 kept Vim and Helix copy-mode grammars in one tmux configuration.
The Helix branch recreated select-mode with a per-pane flag because tmux only has one inclusive selection.
Repeated and mixed word motions exposed that the two models could not preserve the same anchor, cursor, and token boundaries.
The resulting punctuation and whitespace handling was fragile and did not behave like Helix.

## Decision

Replace both profiles with one tmux-native copy mode.
Keep tmux's built-in motions and selection state, plus `v`, `x`, `C`, `y`, `Y`, and the explicit `mi<obj>`/`ma<obj>` text-object prefix.
Do not bind Helix's `_` because tmux cannot trim whitespace from the endpoints of a live selection.
Remove `@copy_profile`, `@copy_select`, its mode-entry hook, the profile branches, and the Helix comparison matrix.

## Consequences

Mixed motions now have one state model and use tmux's own word boundaries.
The configuration no longer offers Helix selection-first word motions or Vim operator-pending yanks such as `yy` and `yiw`.
Selecting before a motion remains available with `v`, and text objects remain available explicitly through `m`.
Whitespace can be trimmed after copying in another tool, but not in copy mode before yanking.
