# ADR-0078: Give Pi's fast model cycle an own extension and config list instead of trimming the scoped model list

Status: Accepted
Date: 2026-09-30

## Context

Pi's `Ctrl+P` cycled through the session's scoped models, which `enabledModels` in `settings.json` filled: the three alias tiers (`alias/top`, `alias/mid`, `alias/cheap` from `model-alias.json`) followed by fifteen concrete models.
A stray cycle could land on a concrete model and leave the fallback chain the aliases exist to provide.
The same list also supplied the `/model` picker and the `/scoped-models` selector, and Pi exposes no extension API that writes `settings.json`.
Two ways existed to make keyboard cycling alias-only: trim `enabledModels` to the three aliases so the native cycle had nothing else to reach, or keep the full list and let an extension own a separate cycle list.
The first coupled the cycle to the picker and startup selection; the second allowed any model in the cycle but had to persist its own list.

## Decision

`app.model.cycleForward` and `app.model.cycleBackward` were emptied in `keybindings.json`, removing `Ctrl+P` and `Shift+Ctrl+P` (`Alt+P` on Windows and WSL).
`extensions/cycled-models.ts` bound `Shift+Right` and `Shift+Left` to step a list read from `cycled-models.json`, defaulting to the three alias tiers when the file is absent or malformed.
It resolved each `provider/modelId` entry through the model registry and switched with `pi.setModel`; entering the list from a model outside it went to the first entry on forward and the last on backward.
A `/cycled-models` command opened a searchable `SettingsList` that toggled models in and out of the file, and `reset` restored the default list.
`enabledModels` was left intact, so `/model` and `/scoped-models` kept the whole catalogue.

## Consequences

`Ctrl+P` stopped cycling models, and the cycle set became the config file rather than the session scope.
`/cycled-models` edited membership; the order the keys step through was the file's order and was not editable from the picker.
The keys worked regardless of what `/scoped-models` held, because the extension read its own list.
`Shift+Left` and `Shift+Right` were extension shortcuts, so `keybindings.json` could not rebind them.
A list entry whose provider lost authentication dropped out of the cycle at press time, and the picker offered only currently available models.
Cycling did not persist the default model, matching the native cycle it replaced.
