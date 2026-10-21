# ADR-0097: Pi model config changes through an approved prompt, not an automatic hook

Status: Accepted
Date: 2026-10-21

## Context

ADR-0094 keeps pi's model catalog fresh, but nothing connects a catalog change to `model-alias.json` or `enabledModels`.
A model that replaces a configured one, such as `claude-haiku-5-5` for `claude-haiku-4-5`, went unnoticed until someone looked, and a dead alias target fails its whole chain.

The alternatives were a hook that rewrites the config when the catalog changes, a bootstrap-step diff report, and a prompt the user runs.
Choosing a tier for a model is a judgment about capability and tool-calling behaviour (ADR-0093), which a bootstrap step cannot make and an unattended rewrite would make silently.

## Decision

The `/sync-models` prompt refreshes the catalog, lists dead and unreferenced models, proposes edits, and writes only after approval.
The `model-drift` extension tells the user when to run it: at TUI startup it names configured models missing from the catalog and models the config's providers added since `state/models-seen.txt`, which the prompt rewrites after every run.
Nothing edits the config unattended.

## Consequences

Model upgrades are noticed at the next startup and applied with review, so no tier changes without the user seeing why.
The warning repeats until `/sync-models` runs, by design.

Accepted limitation: the extension lists new IDs but cannot tell which configured model one replaces; the prompt does that pairing.
Accepted limitation: the seen list is machine-local and built in two places, the extension from the model registry and the prompt from `pi --list-models`; if pi changes that table's columns they diverge and the warning misfires.
Accepted limitation: the warning depends on the catalog cache, which the bootstrap refreshes about daily, so a new model can arrive a day late.
