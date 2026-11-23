# ADR-0132: Record free-pool trials with evidence rather than scores

Status: Accepted
Date: 2026-11-23

## Context

The 2026-11-23 sync priced the OpenCode Go catalog with Artificial Analysis Intelligence Index v5.0.1. The free-pool models printed no composite and no terminal-evaluation components, so an intelligence-per-drain value could not be computed for them. `iceman-contributor-free` is a free, limited-time stealth model with no canonical lab, no published benchmark record, text-only input, training-eligible prompts, and no zero-data-retention guarantee. `hy4-flash-free` is a free Tencent Hy4-flash variant with a 1M context, image input, ZDR, and no training use. One-token and bounded local tool probes showed that both models can answer and drive a simple tool loop; a public report of deterministic tool-result failures on Iceman did not reproduce in this run.

There was no sound basis for claiming that Iceman is more intelligent than hy4-flash-free. A free model with no score must not be ranked by rearranging index components or by treating a successful chat probe as a capability measurement.

## Decision

`$bench` records unscored free models with their availability, coverage, privacy, and evidence, and gives a concrete promotion condition. A model without a comparable composite keeps `n/a` and does not receive an estimated IPD or invented benchmark score. Iceman is benched only, not enabled or placed, because it offers an independent free pool but no comparative advantage over the existing free tail.

## Consequences

The config keeps a durable reason not to re-litigate the free-model choice at the next sync. A later composite, repeated harness turn-completion evidence, or a change in the training/ZDR tradeoff can promote it without rewriting this record.

The cost is that an unscored model with real latent ability stays out until evidence exists. Short local probes are recorded as evidence of availability, not as an intelligence ranking.
