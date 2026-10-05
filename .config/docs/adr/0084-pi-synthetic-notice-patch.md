# ADR-0084: Patch pi-claude-bridge to keep synthetic failure notices off the stream, folding upstream #162 into the #148 index.ts patch directory instead of a second directory or an alias-extension change

Status: Accepted
Date: 2026-10-05

## Context

The `alias/top` chain and the permission reviewer's chain both lead with `claude-bridge` models, and `pi-model-fallback-alias` advances a chain only on *pre-output* failures — it commits on the first text or tool event and never swaps providers afterwards, so a partially delivered turn cannot be retried against a different provider.
Claude Code reports an API failure or a subscription limit as a `<synthetic>` assistant message immediately before the failing `result`, and `pi-claude-bridge` streamed that report as ordinary assistant text.
The turn therefore looked like it had produced output before the failure arrived, and the alias recorded a committed failure — the debug log's `eventCount:5` is `start,text_start,text_delta,text_end,error`.
Pi's agent-level retry then re-ran the same alias, which re-selected the same first target because a committed failure deliberately records no cooldown; three retries later it stopped with `Retry failed after 3 attempts` and the second target was never tried.

Four routes were weighed.
Changing `pi-model-fallback-alias` to cooldown a target after a committed failure, or to special-case an error notice, would widen its careful "never swap after output is visible" contract to cover a case the provider should not have created, and both alter semantics for genuine mid-stream cutoffs.
Reordering the chains leads with a weaker model and only moves the failure.
Waiting for upstream kept every chain pinned to Claude Code until a release.
Patching the bridge addresses the cause: a `<synthetic>` message is Claude Code's own report, not model output, and a native pi provider emits only an error for such a failure.
The wording still reaches pi through the result's `errorMessage`, which the bridge already populates.

The patch library (`patches/apply.sh`) applies each patch directory only to a byte-identical pristine target, so two upstream changes to the same file cannot live in two directories: the second would always report drift.
The existing `pi-claude-bridge-standalone-index` directory already owned `index.ts` for upstream #148.

## Decision

Patch `processAssistantMessage` to detect `message.model === "<synthetic>"`, keep the blocks on the failed turn's output, and emit no stream events.
The failure is then a call that produced no output, so a pre-output failover advances; the error event still carries Claude Code's wording.

Carry the fix as the `pi-claude-bridge-index` patch directory — the former `pi-claude-bridge-standalone-index`, renamed and regenerated to hold both upstream #148's hunks and the new #162 hunk — with the marker `Local patch: pi-claude-bridge#162`, which appears only when the full patch is applied and so turns any partial upstream merge into a drift warning instead of a silent skip.

Push the change upstream as [elidickinson/pi-claude-bridge#163](https://github.com/elidickinson/pi-claude-bridge/pull/163) (issue [#162](https://github.com/elidickinson/pi-claude-bridge/issues/162)) and add a unit test that pins the contract: only `start`/`thinking_*` events may precede the terminal error, so a consumer that commits on anything else can still fail over.

## Consequences

An exhausted Claude quota now fails over to the next target in the chain instead of pinning it to Claude Code until the reset.
Direct (non-alias) bridge turns are unaffected: the notice still reaches the failed turn's content and the terminal error message.

The `pi-claude-bridge-index` directory now couples two upstream changes with different drop conditions.
The marker only detects the fully patched form, so a release that merges one and not the other reports drift and the directory must be regenerated against the new pristine file; dropping one hunk is a normal rebase, not a deletion of the directory.

The hunk is deleted once #163 ships in a release; the #148 hunks stay until [elidickinson/pi-claude-bridge#148](https://github.com/elidickinson/pi-claude-bridge/pull/148) does.
