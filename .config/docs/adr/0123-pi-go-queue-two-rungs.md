# ADR-0123: Spend a tier's Go rungs on capability then one larger cap, and let top alone carry a high-drain head

Status: Superseded by [ADR-0125](0125-pi-one-go-rung.md)
Date: 2026-11-22
Supersedes: [ADR-0121](0121-pi-single-prompt-exclusion.md)

## Context

The 2026-11-22 sync priced the whole OpenCode Go catalog for the first time (`pi-model-cost --all`) rather than the handful of models the config referenced, and three things fell out that the previous decision could not see.
The strongest cheap Go models were not in any tier: `muse-spark-1.3-contributor` at 37.0 on index v5.0.1 with a 1.00% drain and the best intelligence-per-drain on the board, and `hy4` at 35.0 with a 9.73% drain, against `glm-5.3`'s 32.0.
The single-prompt group was larger than the two models ADR-0121 knew about, and its head was the strongest Go model of all: `gemini-4-argon` 50.0, `kimi-k3.1-pro` 46.0, `qwen4-max` 43.0, `kimi-k3` unscored at 180% drain.
And `muse-spark-1.3-contributor` answered our key with a 400: the endpoint requires the account to opt into paid endpoints that train on request data.

ADR-0121 banned every flagged model from every chain on the ground that its spend comes out of the pool the cheaper tiers answer from.
That ground still holds for `mid` and `cheap`, which run most turns, but not for `top`: in the retained session history `top` is 1 888 messages against `mid`'s 12 318, and excluding argon left the tier 18 index points below the best Go model it could actually reach.

The same logs settled how many Go rungs a tier should hold.
Only `glm-5.3` (8 492 attempts), `deepseek-v4.1-flash` (1 006) and `mimo-v2.6-flash` (396) were ever reached; `mid`'s trailing four Go rungs had none.
The reason is arithmetic: a second Go rung fires only on a failure specific to the first, and it outlives that failure only on a larger monthly cap — otherwise both lock out together.

## Decision

A tier carries at most two paid Go rungs: the strongest model that answers, then one whose monthly cap is strictly larger, so it is still answering when the first locks out.
Any further Go rung is removed as unreachable.

`top` alone may head with a model above the 25% drain the cost script flags, because that tier answers rarely and a larger-cap rung backs it: `top` is `claude-opus-5-5`, `gemini-4-argon`, `glm-5.3`.
`cheap` and `mid` keep ADR-0121's exclusion and each drop to `deepseek-v4.1-flash` then `glm-5.3`, followed by their free tails (ADR-0120).

`hy4` is declined though it answers: 3 index points above `glm-5.3` at five times the drain, when `glm-5.3`'s cap is the tier's endurance anchor.
`muse-spark-1.3-contributor` is excluded by the endpoint's training consent rather than by cost, and would displace the `cheap` and `mid` leaders if the account ever opts in.

## Consequences

Behind Opus, `top` gains 18 index points and gives up endurance: argon drains at 60.0% of the five-hour window per 1M tokens, doubling to 120% in its peak windows, so one 200k-token turn costs 12–24% of the window that `cheap` and `mid` also draw on, and its $30 cap ends it after roughly 60 such turns.
Reversing it is one line: the head returns to `glm-5.3`.

`cheap` and `mid` lose rungs that were never reached, so no observed behaviour changes; `mid` now answers on two Go rungs instead of six, and every removed model stays enabled for direct selection.

Accepted limitation: the cap rule assumes failures are per-model caps rather than provider-wide 429 or 5xx storms, and a provider-wide failure takes the whole Go queue with it; the free pool and claude-bridge are what remain.
Accepted limitation: argon's drain is catalog arithmetic, not a measured spend; if a real `top` turn costs visibly more of the window than this predicts, the head goes back to `glm-5.3` and this record is superseded.
Accepted limitation: `kimi-k2.7-code`, `mimo-v2.6-pro`, `glm-5.3-flash` and `minimax-m3.1-flash` stay enabled and unplaced, so `/sync-models` will list them as unreferenced on every run; this record is the answer, and their `terminalBench40` failure or smaller caps are why.
