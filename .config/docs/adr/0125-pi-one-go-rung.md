# ADR-0125: Carry one Go rung per tier, and keep the draining head out of them

Status: Accepted
Date: 2026-11-22
Supersedes: [ADR-0123](0123-pi-go-queue-two-rungs.md)

## Context

ADR-0123 gave each tier two Go rungs, the second chosen for a strictly larger monthly cap, and let `top` head with `gemini-4-argon` on capability.
Both halves failed once the cap was read as the arithmetic actually uses it.

The cost script's drain divides the blended price by the cap, so a small cap raises the drain — `gemini-4-argon`'s 60% per 1M tokens exists because its $30 cap is small against $2.00/$10.00 pricing.
In tokens the caps are not remotely comparable: argon allows about 8M tokens a month, `glm-5.3` about 250M, `deepseek-v4.1-flash` about 415M.
At a 200k-token turn argon spends 12% of the five-hour window (24% in its peak hours) against `glm-5.3`'s 0.4%, and that spend comes out of the pool `cheap` and `mid` answer from.
`top` is rare, but 30× the drain to gain 18 index points over the durable rung it falls back to is a poor trade for the tiers that run all day.

The second rung failed for a related reason: it can only help when the first model's *own* cap locks out, because the quota itself is shared and a drained pool fails every Go model at once.
For cheap models that cap never binds, so the rung behind the leader is unreachable, which is what the retained logs showed before ADR-0123 was written (mid's trailing four Go rungs, zero attempts).
Argon was the only model whose cap was small enough to justify a backstop, and it is the model being dropped.

The account later opted into paid endpoints that train on request data, which unblocked `muse-spark-1.3-contributor`: 37.0 on index v5.0.1, a 1.00% drain, $0.10/$0.20 per 1M, 1M context, and above every rung in any tier.
Its price for that is the toggle itself — every prompt through it is eligible for training — so it is on trial outside the chains, recorded in the backlog as open work rather than decided here.

## Decision

A tier carries one opencode-go rung.
A second is admitted only when the leader's monthly cap is small enough in tokens to bind before the pool drains, which no model in the current queue satisfies.

`top` is `claude-opus-5-5`, then `glm-5.3`, then `openai-codex/gpt-5.6-terra`; `mid` is `claude-sonnet-5-5` then `glm-5.3`; `cheap` is `deepseek-v4.1-flash` then `claude-haiku-5-5`.
`glm-5.3` holds the paid rungs in `top` and `mid` because a rung is chosen for what it can still do: 41.9% against 33.8% on Terminal-Bench 4.0 and 33.5% against 25.0% on CritPt v2, a flat 2.00% drain instead of one that doubles in peak hours, and a $500 cap against $100, for one composite point that `deepseek-v4.1-flash` earns on knowledge evaluations this harness does not exercise. `cheap` keeps `deepseek-v4.1-flash` regardless: its turns ask for less, it costs a tenth as much per token and drains less outside peak hours, and holding it there leaves the two Go rungs unlike each other, so one model's failure does not empty both halves of the pool.
Each keeps its free tails (ADR-0120), and `reviewer` is unchanged.
`gemini-4-argon` leaves every chain and is no longer enabled for selection; `muse-spark-1.3-contributor` stays enabled for direct use and in no chain.

The retained alias logs then showed what the pool model had assumed away: claude-bridge drains one five-hour window shared by every tier, and its bridge reports that window at 0.9 utilisation with overage rejected.
Measured commit rates were 80% for `sonnet-5-5`, 30% for `haiku-5-5` and 0 of 9 for `opus-5-5` against 99% for every Go rung.
Because `mid` carries most of the traffic, it spends that window first, so `top`'s Opus lead is opportunistic rather than dependable — the tier is expected to answer on `glm-5.3`.
`openai-codex/gpt-5.6-terra` (32.0, tied with `glm-5.3`) was added behind it as the only rung drawn from a pool no other tier touches.

## Consequences

Traffic spends the shared pool at a fraction of the previous rate — the leaders are now 1.20% and 2.00% drain models instead of a 60% one — and the chains shrink to at most four rungs.

A tier's fallback is still a large step down from its lead: `sonnet-5-5` at 54.5 falls to 32.0, and nothing the Go pool sells closes that gap affordably — `gemini-4-argon` reaches 50.0 at 30× the drain, and the 37.0 model is the one on trial. That gap is a property of the pool, not of this ordering.

Accepted limitation: one Go rung means a model-specific failure — a 429, a 5xx, a tool-call regression — drops the tier straight to claude-bridge and then the free pool, with no intermediate same-pool rung.
Accepted limitation: `top` is now two rungs deep, so a failure on `glm-5.3` has nothing below it; `hy4` (35.0 at a 9.73% drain) is the honest intermediate and is not there because it costs 20× the leader per token.
Accepted limitation: `muse-spark-1.3-contributor` is on trial outside the chains (the backlog entry owns it), so the Go leaders here are the ones measured before that account change; if the trial is taken up, it displaces `deepseek-v4.1-flash` and this record is superseded.
Accepted limitation: the token figures for the caps are derived from catalog prices, not from a measured month of traffic.
