# ADR-0120: Close a tier's tail with free-pool rungs, and keep the config comment to the rule

Status: Accepted
Date: 2026-11-22

## Context

ADR-0103 established that a cheap Go rung behind an expensive one buys endurance rather than a second allowance, because OpenCode Go spends one shared quota at each model's own price.
Every tier therefore ended inside the paid pools — claude-bridge, opencode-go, openai-codex — and once those drained, the turn failed.
The free opencode-go models were already known to answer after the paid quotas are gone (verified 2026-10-04), and they draw on a pool of their own, but they sat only in the reviewer chain.

Three placements were available: leave them out and keep tiers inside the paid pools; put a free model inside a tier ahead of scored Go rungs on its measured latency, as the reviewer chain does; or append them behind the last scored rung of the tiers that can run dry in ordinary work.
Ahead of a scored rung was rejected: Artificial Analysis has no score for any of them (`n/a`, not a low one), no agentic benchmark covers them, and the only harness evidence is one ~14k-token reviewer prompt each, answered with thinking off.
Ranking an unscored model above a measured one is the guess ADR-0103's ordering keys exist to prevent; ranking it last claims nothing beyond a separate pool.

The same sync found the `model-alias.json` `$comment` had grown to 828 words carrying prices, monthly caps and index scores from the last sync — the facts ADR-0118 had just moved into `bin/pi-model-cost` precisely because they move between syncs.
It had already disagreed with the endpoint once (glm-5.3 recorded at a $200 cap against $500 live).
ADR-0103 asked the comment to state the ordering rule where the rungs are read, not to freeze the evidence for each rung, and nothing reads `$comment` at runtime.

## Decision

`cheap` and `mid` end with `opencode-go/longcat-2.5-free` and `opencode-go/hy4-flash-free`, after every rung that has harness or benchmark evidence.
`beam-free` stays in the reviewer chain only, because it takes no images and both tiers do.
The placement claims pool independence, not capability: the free models' evidence stays the one reviewer prompt each, and that limitation is stated beside them.

The `$comment` carries the ordering rule, the shared-pool arithmetic, which pools are independent, and the reviewer chain's latency and patch constraints.
It carries no prices, caps or scores, and points at `bin/pi-model-cost` for those (ADR-0118) and at ADR-0103 for the rule.

## Consequences

A tier now keeps answering past the Go and Codex quotas from a third pool, at the price of one more failure mode: as the last rung, a model that stalls costs up to the alias's default 30s first-event timeout before the turn fails, where before it failed at the previous rung.

Re-applying ADR-0103 to the live v5.0.1 table in the same sync inverted two orders the frozen v4.3.2 scores had set: `deepseek-v4.1-flash` (33) now leads both `cheap` and `mid`'s Go rungs ahead of `mimo-v2.6-flash` (27) and `glm-5.3` (32), which was the trial condition recorded beside `glm-5.3`.

No price or score survives in the config any more, so a stale one cannot be read as current; the cost is that placing a rung now requires running the script first, and an unrecorded manual reorder leaves no trace in the file.

Accepted limitation: the free models' pool independence rests on the 2026-10-04 check and on undocumented rate limits, so a rate-limited free tier makes these rungs fail rather than fall back.
Accepted limitation: nothing has verified that they can drive a multi-turn tool loop, which is what a tier does and what the reviewer prompt does not exercise; the first real use replaces that evidence or removes the rungs.
Accepted limitation: the 30s first-event timeout is a default, not a measurement of any free model's tail.
