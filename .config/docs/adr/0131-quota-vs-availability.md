# ADR-0131: Distinguish quota exhaustion from model unavailability in model sync

Status: Accepted
Date: 2026-11-23

## Context

The 2026-11-23 model sync probed conditional rungs with one-token requests. OpenCode Go returned 402 insufficient balance for the contributor model and Claude bridge returned 429 rate limits for Claude models. Those responses show that the shared account quota is exhausted, not that a model has lost access, refused requests, or become unsuitable. Treating them as gate failures would have removed a deliberately unplaced contributor model from chains it was not in and removed enabled Claude models for a temporary account condition.

The same sync found that the configured `longcat-2.5-free` and its catalog successor `longcat-2.5` both returned 410 ModelDeprecated. That is a real availability condition and justifies removing the entry without recording a replacement in `$bench`, because a deprecated model has no promotion path worth preserving.

## Decision

Model sync interprets a plain 402 or 429 from a paid pool as quota exhaustion and leaves model placement and enablement unchanged. Access-gate or endpoint failures such as a 400 with a training-consent requirement, a 404/410 for a deprecated or missing model, or a deterministic tool-path failure remain grounds for removing a rung or withholding placement.

Deprecated models are removed from aliases and `enabledModels` and are not added to `$bench`. `$bench` stays a record of live models rejected on capability, cost, conditions, or evidence, not a tombstone for IDs the provider will never serve again.

## Consequences

A sync in an exhausted account can still reconcile the catalog without mistaking temporary quota errors for durable model decisions. Availability probes still have to be read by status and message, not by a generic nonzero exit.

The cost is that the sync cannot verify conditional access while the whole pool is exhausted; a gated model might pass only after top-up. The operator's own turn-completion evidence remains the reason to keep a model out of a chain, as with the contributor model that stalls mid-task.
