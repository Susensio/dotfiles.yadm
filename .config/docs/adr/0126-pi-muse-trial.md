# ADR-0126: Trial a second Go rung above each tier's schema rung, and re-check its conditions

Status: Accepted
Date: 2026-11-22

## Context

ADR-0125 allowed each tier one Go rung, on the finding that a shared pool fails every Go model at once, so a second rung only helps when the first model's own monthly cap binds.
The account then opted into paid endpoints that train on request data, which unblocked `muse-spark-1.3-contributor`: 37.0 on index v5.0.1, a 1.00% drain, $0.10/$0.20 per 1M, 1M context, verified answering and running a tool call, and above every rung in every tier.

Keeping it out of the chains meant the config could not use the best model its pool sells.
Replacing each tier's existing Go rung with it would have discarded the schema the tiers were tuned around, so withdrawing it later would be a rewrite under pressure rather than a deletion.

## Decision

`muse-spark-1.3-contributor` sits above each tier's existing Go rung: `top` is Opus, muse-spark, `glm-5.3`, codex; `mid` is `sonnet-5-5`, muse-spark, `glm-5.3`; `cheap` is muse-spark, `deepseek-v4.1-flash`.
Every tier keeps its pre-trial schema directly behind the new rung, so withdrawing it restores the previous chains exactly, one line per tier.

This suspends ADR-0125's second-rung rule for the trial's duration and does not repeal it: below the trial rung, each tier still carries one schema Go model.

Its access is conditional — an account-level toggle for training-class endpoints, plus a contributor variant whose availability may depend on plan status — so `/sync-models` verifies it answers before trusting the table, and any change to its terms is the trigger to withdraw it rather than to re-plan the tiers.

## Consequences

Each tier now reaches the strongest cheap model the pool sells before spending anything on its schema rung, and a failure or withdrawal costs one line.
The cost is that a tier can burn two Go models' worth of pool before reaching a different pool, which ADR-0125 exists to avoid; that is accepted because the second rung here is a rollback target rather than a hedge against caps.

Accepted limitation: every prompt through the trial rung is training data, by the account's own choice.
Accepted limitation: the conditions are not observable from the catalog, so a silent change — a 400, a plan downgrade — shows up as failed turns before it shows up in any table.
Accepted limitation: while the trial runs, the "one Go rung per tier" statement in ADR-0125 and in `model-alias.json`'s comment is false without this record.
