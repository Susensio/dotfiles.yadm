# ADR-0078: Cycle Pi model alias tiers from an own extension instead of trimming the scoped model list

Status: Accepted
Date: 2026-09-30

## Context

Pi's `Ctrl+P` cycled through the session's scoped models, which `enabledModels` in `settings.json` filled: the three alias tiers (`alias/top`, `alias/mid`, `alias/cheap` from `model-alias.json`) followed by fifteen concrete models.
A stray cycle could land on a concrete model and leave the fallback chain the aliases exist to provide.
The same list also supplied the `/model` picker and the `/scoped-models` selector.
Two ways existed to make keyboard cycling alias-only: trim `enabledModels` to the three aliases so the native cycle had nothing else to reach, or keep the full list and add a binding that moved only between tiers.

## Decision

`app.model.cycleForward` and `app.model.cycleBackward` were emptied in `keybindings.json`, removing `Ctrl+P` and `Shift+Ctrl+P` (`Alt+P` on Windows and WSL).
`extensions/alias-cycle.ts` bound `Shift+Right` and `Shift+Left` to step the tier ladder in `top`, `mid`, `cheap` order, wrapping at each end, resolving each name through the model registry and switching with `pi.setModel`.
Entering the ladder from a concrete model went to `top` on forward and `cheap` on backward.
`enabledModels` was left intact, so `/model` and `/scoped-models` kept the whole catalogue.

## Consequences

`Ctrl+P` stopped cycling models, and the concrete entries became reachable only through the `/model` picker.
The tier keys worked regardless of what `/scoped-models` held, because the extension named the tiers directly rather than reading the scope.
`Shift+Left` and `Shift+Right` were extension shortcuts, so `keybindings.json` could not rebind them, and adding or renaming a tier meant editing the extension's tier list to match `model-alias.json`.
Cycling did not persist the default model, matching the native cycle it replaced.
