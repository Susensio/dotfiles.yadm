# ADR-0094: Refresh pi's model catalog in the bootstrap, gated daily and tolerant of failure

Status: Accepted
Date: 2026-10-18

## Context

Pi resolves `enabledModels` and the alias targets against a model catalog cached at `agent/models-store.json`.
That cache is only written when a refresh runs: `pi update --models` does it explicitly, and the TUI does it when the model selector opens.
A machine driven headlessly never opens the selector, so it keeps whatever catalog shipped inside the installed binary.

ADR-0092 ordered the tiers against a catalog read on one date and accepted that the cache was a snapshot.
The snapshot proved to lag the provider: with the catalog bundled in pi 1.3.0, a model added days earlier warns `No models match pattern "opencode-go/beam-free"` and, when it is an alias rung, the alias silently loses that rung instead of failing — the same silent degradation the ADR named, reached through a different door.

Refresh-on-demand was the alternative, and it already exists: opening `/model` or `/scoped-models` refreshes, and `pi update --models` is a one-word command.
Neither helps the case that matters, a fresh clone or a `yadm bootstrap` that installs pi and immediately expects the tracked `settings.json` to mean something, because both require a person to know the cache is stale before anything tells them.

Two behaviours decided the step's shape.
A failed refresh exits non-zero, and the bootstrap aborts the whole run on a failing step, so an unguarded call would let a network hiccup fail an otherwise good bootstrap.
A failed refresh also leaves the existing store in place rather than truncating it, so retrying costs nothing and losing the cache is not a risk worth guarding against.

## Decision

Refresh the catalog from a bootstrap step at `yadm/bootstrap.d/pi/models.sh`, in the ADR-0057 shape, and let the step succeed in every case.
It skips when pi is not installed, skips when the store is newer than a day, and converts a failed refresh into a warning plus a debug line instead of a non-zero exit.

The daily gate matches the Nerd Font step's shape and exists because the bootstrap reruns on every `omarchy update` while the catalog only matters when it is stale.

## Consequences

A fresh clone resolves the tracked model configuration without the operator knowing the cache exists.
The bootstrap now touches pi's state directory, so a machine that has never authenticated still gets a store file; pi writes `{}` in that case and the next run overwrites it, which the daily gate keeps from happening on every failed attempt.

Accepted limitation: the step refreshes what the providers publish, not what this repo expects, so an alias rung naming a model the provider has dropped stays broken until someone re-syncs and edits the config.
Accepted limitation: a refresh that fails is invisible unless the bootstrap output is read, and the failure mode it produces — a missing rung — is the silent one this step was added to prevent.

