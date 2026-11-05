# ADR-0093: Lead each Pi tier with the strongest model that answers, and demote a metered model behind a stronger cross-provider one

Status: Superseded by [ADR-0103](0103-pi-rung-order-shared-quota.md)
Date: 2026-10-18
Supersedes: [ADR-0092](0092-pi-tier-order-by-intelligence.md)

## Context

ADR-0092 ordered every tier's rungs by measured intelligence, but it applied that rule only inside the OpenCode Go rungs and left the mid tier leading with `deepseek-v4.1-flash` (39) ahead of `claude-sonnet-5-5` (56).
That inconsistent application had a cost the ADR did not state: on the index it had just adopted, the mid tier was spending its first attempt on its weakest cross-provider option, and only reached a model 17 points stronger after DeepSeek either failed or was cooling down.
The ordering was a transcription of what the plan happened to contain, not a decision about which model should answer first.

The alternatives were to keep DeepSeek leading because it is metered and unlimited-in-context inside one subscription, to lead with Sonnet because it measures stronger, or to drop the aliases and name one model per role.
Leading with DeepSeek treats a rate-limit hedge as if it were a capability argument; the cross-provider spread exists so one exhausted subscription does not empty a tier, and that job belongs to the second and later rungs.
Dropping the aliases would have returned every exhausted quota to a prompt.

## Decision

Lead every tier with the strongest model that can answer there, and let the cross-provider hedges sit behind it.
`alias/mid` now leads `claude-bridge/claude-sonnet-5-5`, followed by `deepseek-v4.1-flash` as the first Go rung, then `glm-5.3-flash`, `kimi-k2.7-code` and `mimo-v2.6-pro`; `alias/top` and `alias/cheap` are unchanged.

The turn-completion rule from ADR-0092 still overrides raw score: a model with a documented tool-call repetition failure mode does not lead a tier, which is why `kimi-k3` and `mimo-v2.6-pro` remain non-leads despite measuring above several models that do lead.

## Consequences

A tier's first attempt is now its strongest option, and the fallbacks degrade by reliability rather than by availability-per-dollar, so the aliases claim one property consistently instead of two at different depths.
Mid-tier traffic moves onto the Claude subscription, which puts more weight on the claude-bridge patches and on that subscription's quota; a Claude outage now costs the tier its lead rather than a late fallback.

The `$comment` must state the lead rule because the fallback order deliberately contradicts the score order, and a reader comparing the two without it would read the file as sloppy rather than deliberate.
Accepted limitation: raw index score is used as if it were capability for a specific repository, and none of these ranks were measured on this project's own work.
