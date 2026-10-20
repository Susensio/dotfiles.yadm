# ADR-0092: Order Pi's model tiers by measured intelligence and keep a looping model out of every fallback lead

Status: Superseded by [ADR-0093](0093-pi-tier-lead-by-capability.md)
Date: 2026-10-18

## Context

Pi selected its three model tiers and its permission reviewer's chain from an OpenCode Go plan whose per-model access is capped in dollars, not requests: each model carries its own monthly cap, and the 5-hour window is 20% of it while the week is 50%.
Nothing in that scheme is shared, so spending less on one model buys nothing on another, which removed scheduling and budget-shuffling as ordering levers and left capability as the only reason to prefer one target over another.

Three forces made the previous ordering wrong.
A stale third-party price comparison had ranked `kimi-k2.7-code` beside the frontier open models; Artificial Analysis' Intelligence Index v4.3.2 put it at 26, below the aliases' own `cheap` target (`mimo-v2.6-flash`, 38) and far below models then left disabled (`glm-5.3-flash` 42, `kimi-k3` 44, `glm-5.3` 45, `mimo-v2.6-pro` 46).
Go's catalog had also moved: eleven models arrived, `claude-haiku-5-5` was the first Anthropic model on the plan, and the free tier turned over completely.
Finally, the catalog Pi had cached no longer matched what Go served, so three stored IDs were dead and nine served IDs were missing.

The alternatives were to keep the chain ordered by stability and known behaviour, to reorder it purely by index score, or to drop the aliases and name one model per role.
A pure score ordering was rejected because the two strongest open models fail in a way fallback positions amplify: `kimi-k3` re-issues identical tool calls at large context and cannot disable thinking, and Xiaomi published a post-mortem on tool-call repetition in `mimo-v2.6-pro`.
Dropping the aliases would have returned every exhausted quota to a prompt.

## Decision

Order each tier's OpenCode Go rungs by measured intelligence, and gate the lead rung on tool-calling stability rather than score.
The mid tier leads with `deepseek-v4.1-flash`, gains `glm-5.3-flash` second, and keeps `claude-sonnet-5-5` and `kimi-k2.7-code` as cross-provider and known-behaviour fallbacks; the top tier keeps `kimi-k2.7-code` first among Go models and gains `glm-5.3` fourth; the cheap tier is unchanged.

The reviewer's chain gained `beam-free` as its first Go rung and `claude-haiku-5-5` as the first quota-bound one, because free capacity outlasts metered capacity when the plan drains.

The model cache was re-synced from the served catalog before the config was edited, so every target resolves.
A model measured only by its vendor, or reachable only under an undocumented ID, did not earn a rung.

## Consequences

A tier now degrades by measured capability instead of by habit, and the order is checkable against a published index rather than remembered.
Fallback positions favour models that finish a turn: the best-scoring open models are reachable by name but hold no lead, which costs their capability whenever the primary is unavailable and buys not stalling in a loop.

OpenCode Go's catalog turns over faster than the aliases: free IDs disappeared within days of being documented, and one documented ID (`step-5-preview-free`) had already been replaced by an undocumented one (`step-5-preview`) while the docs still named the dead one.
The cache is therefore a snapshot — checked 2026-10-18 — not a source of truth, and a rung can silently rot into an unknown-target error, which fails the whole chain rather than skipping one entry.
Re-run `pi update --models` and compare against `https://opencode.ai/inference/go/v1/models` before trusting a failing alias.

The free-model rungs depend on models that train on nothing and may be withdrawn without notice; a reviewer whose first Go rung is free is a reviewer that loses capacity silently.
Accepted limitation: no automated check re-verifies the rungs, because a wrong rung only surfaces when a permission decision is already waiting.

