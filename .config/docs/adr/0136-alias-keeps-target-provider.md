# ADR-0136: Keep the target provider on alias messages instead of relabelling them to alias

Status: Accepted
Date: 2026-11-25

## Context

From about 2026-11-10 Sonnet sessions through `alias/*` drained the five-hour Claude window far faster than on 2026-11-05 and 11-06.
`pi-model-fallback-alias` stored every assistant message as provider `alias`, with the concrete model only in `responseModel`; its README documents that as the logical identity.
`pi-claude-bridge` hashes and replays a signed thinking block only for messages whose provider is `claude-bridge`, a gate its own test pins, because a foreign provider's signature cannot be replayed.
The bridge records a digest of each assistant message as emitted, with provider `claude-bridge`, and compares it with pi's stored copy on the next call.
The stored copy hashed without its thinking block, so the last assistant message never matched and each call after a thinking turn took the `prefix-write row=7` path: a new Claude session and a cache miss.
Live runs reproduced it under `alias/mid` on bridge 0.13.0 and on 0.11.0 with the older SDK, and not on `claude-bridge/claude-sonnet-5-5` called directly.
The bridge could not tell a foreign model from Claude behind the alias, and the alias can fail over to a non-Claude target whose thinking must not replay, so only the alias knows which provider answered.
Alternatives weighed:
- the bridge digesting signed thinking whatever the provider, which contradicts its deliberate gate;
- a native pi virtual-model router or `@erikenz/pi-model-fallback`, which lose the alias's pre-commit stall timeouts (ADR-0120) and shared cooldowns;
- direct subscription-OAuth packages, which route subscription credentials through a third party against Anthropic's terms, with documented enforcement;
- thinking off, which costs reasoning;
- calling `claude-bridge` directly, which loses the failover of ADR-0092 and ADR-0125.

## Decision

The patch library carries `pi-model-fallback-alias-keep-provider`, which deletes the `provider: aliasModel.provider` line from `withAliasMessageIdentity`.
Stored messages keep the answering target's provider; `api`, `model` and `responseModel` stay aliased.
The change was installed on 2026-11-24 and, over the following 30 hours of use, produced no `prefix-write` on any session that loaded it.

## Consequences

- The patch is rebased by the library on each alias update; drop it if the alias ships an option to keep the target provider, and file the relabel against the alias upstream first.
- Mixed-provider history after a mid-session failover, the footer and usage attribution, and the permission reviewer were not exercised with the patch.
- Remaining full cache writes were ordinary: idle expiry, a fork after a `dirtyTail`, and a deliberate model switch, which rebuilds the session by design.
- The reason the regression began on 2026-11-10 was not found: the bridge's gate is identical from 0.10.0 to 0.13.0 and the SDK bump does not reproduce it.
- Whether the quota burn is gone rests on the sync log and the cache numbers, not on the quota meter.
