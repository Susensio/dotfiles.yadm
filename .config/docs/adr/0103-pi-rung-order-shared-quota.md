# ADR-0103: Order a tier's rungs by turn completion, then by evidence, under one shared OpenCode Go quota

Status: Accepted
Date: 2026-11-05
Supersedes: [ADR-0093](0093-pi-tier-lead-by-capability.md)

## Context

ADR-0093 ordered each tier's rungs by turn-completion reliability behind a capability-chosen lead.
The reason recorded beside that choice — in the config comment and in the commit that first ordered the tiers, `pi: order the model tiers by capability and measured intelligence` — was that "Go caps each model separately, so a cheaper model never funds a pricier one".
That premise was wrong.
OpenCode Go draws every rung from one shared quota, and each call spends it at that model's own price, so a cheap rung adds no independent allowance; it buys how long the tier can keep answering out of the same pool.

Two problems followed from the false premise.
The comment asserted a hedge that does not exist, which would have justified stacking cheap rungs for availability they never provide.
And `alias/top` treated reliability as the only property behind its lead, leaving a 32-point gap at its second rung: `claude-opus-5-5` (58) fell straight to `kimi-k2.7-code` (26) while `deepseek-v4-pro` (53) sat in the catalog unreferenced and unreachable through any alias.

The alternatives were to keep reliability as the only ordering key behind the lead, to order every rung by index score, or to name the properties that actually distinguish a rung and rank them.
Score-only ordering would place a model with a documented tool-call repetition failure mode above a clean one, which ADR-0092 already rejected.
Reliability-only ordering keeps the cliff.

## Decision

Lead a tier with the strongest model that answers there, as ADR-0093 decided, subject to ADR-0092's turn-completion override.

Order every rung behind the lead by three keys, applied in order:

1. turn completion observed in this harness, where the model has been used;
2. otherwise agentic benchmark evidence — Terminal Bench, DeepSWE, tool-use suites — rather than a composite intelligence index;
3. where neither key separates two rungs, the cheaper model first, because one shared quota drains at each model's price.

`alias/top` now places `opencode-go/deepseek-v4-pro` second on key 2 (Terminal Bench 2.1 87.9, DeepSWE 62.7), ahead of `opencode-go/kimi-k2.7-code`.
`kimi-k2.7-code` drops to third and keeps its harness record as the reason it still sits above the higher-scoring `mimo-v2.6-pro` and `glm-5.3`.
Scores are Artificial Analysis Intelligence Index v4.3.2, read 2026-11-05.

The config comment states the shared pool once, in the place where the fallback ordering is explained, so a reader comparing rung order against score order meets the rule where it applies.

## Consequences

A tier's second rung is now chosen for capability wherever agentic evidence exists, so `top` no longer sheds half its capability the moment Opus is unavailable.
The cost is that the tier burns its shared Go quota 3–4× faster per token on that rung than the cheap model it displaced: `deepseek-v4-pro` costs 0.66/1.98 per million tokens against `deepseek-v4.1-flash` at 0.15/0.60.
Cheap rungs behind it are endurance rather than an availability hedge, and that distinction has to be stated wherever rung order is justified, because the two properties look identical in a list of models.

Future syncs can no longer argue that a cheap rung outlasts an expensive model's separate allowance.
The only endurance claim this config can make is price per token against one pool.

Accepted limitation: the endurance claim is arithmetic on catalog prices, not a measured drain, and OpenCode Go's pool size and reset behaviour are undocumented here.
Accepted limitation: keys 1 and 2 rank evidence of different kinds — harness history against public benchmarks — so one bad local session can outrank consistently strong public agentic scores.
That was accepted because turn completion in this harness is what a tier actually needs, and the harness evidence is the scarcer of the two.
Accepted limitation: index score still stands in for capability for this repository's own work, as ADR-0093 accepted; none of these ranks were measured here.
