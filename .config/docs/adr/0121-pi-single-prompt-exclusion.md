# ADR-0121: Keep single-prompt-rung models out of the tier chains, top included

Status: Superseded by [ADR-0123](0123-pi-go-queue-two-rungs.md)
Date: 2026-11-22

## Context

ADR-0103 placed `opencode-go/deepseek-v4-pro` second in `alias/top` on key 2 — agentic benchmark evidence, Terminal Bench 2.1 87.9 and DeepSWE 62.7 — deliberately ahead of models with higher composite index scores.
The 2026-11-22 sync priced that rung against the live table and found `single-prompt-only`: 30.8% of the five-hour window per 1M tokens, on a $15 monthly cap, at 23 on index v5.0.1.
The index drop alone was not grounds to move it, because ADR-0118 records that scores are comparable only within one version and the v4.3.2 ranks this order was set on are gone.

Two further facts decided it.
The drain is spend out of the same pool `cheap` and `mid` answer from, so a rung taken in `top` is paid for by the tiers that run dry first — at top-tier context sizes one prompt on that rung can take a third of the window away from everything else.
And the ranking it was relying on has no affordable alternative: the only Go models scoring above glm-5.3's 32 are gemini-4-argon (50) at 60% drain and kimi-k3.1-pro (46) at 120%, one of which exceeds a whole window per million tokens.
A tier whose whole purpose is capability therefore cannot draw its capability from OpenCode Go at all; `top`'s real capability comes from claude-bridge, and its Go rungs are a queue behind it.

The alternatives were to keep the rung where it was with the trade-off written down (the backlog entry this replaces), to reorder it within the chain so the same drain landed lower, or to exclude high-drain models from tier chains altogether.

## Decision

A model the cost script flags `single-prompt-only` — over 25% of the five-hour window per 1M tokens — stays out of every alias chain, however it scores.
The flag is the rule, not the model: a price, cap or index change that clears the flag re-admits `deepseek-v4-pro` (or any other) without revisiting this record.

`alias/top`'s Go rungs become `kimi-k2.7-code` on ADR-0103 key 1 (its clean tool-calling record in this harness, 13.0% drain, 262k context), then `glm-5.3` (32, 2.0% drain, $500 cap), then `mimo-v2.6-pro` (30, 17.4% drain), whose documented tool-call repetition failure mode keeps it last.
`deepseek-v4-pro`, `gemini-4-argon` and `kimi-k3.1-pro` stay enabled for direct selection and are in no tier.

## Consequences

A `top` turn can no longer spend a third of the five-hour window on one prompt and leave `cheap` failing for the rest of it.
The price is that `top` behind Opus is now weaker on paper than before — a 262k-context rung scored on harness behaviour, a 32, and a 30 — because the rungs that would score higher are excluded by cost rather than quality.

`/sync-models` will keep listing `deepseek-v4-pro` as an unreferenced model, since dropping it from a chain does not remove it from the catalog; this record is the answer, and re-adding it requires a change that clears the flag.

Accepted limitation: benchmark evidence no longer buys a rung, so a model can be demonstrably stronger agentically and still sit out of every chain on price.
Accepted limitation: the 25% threshold is the script's, chosen once, and not a measured cost of a real turn; it is high enough that a rung at 24% would still be taken.
Accepted limitation: `kimi-k2.7-code` leads the Go queue on harness evidence alone and is `n/a` on v5.0.1, so the tier's first fallback is unscored.
