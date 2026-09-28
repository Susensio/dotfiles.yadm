# ADR-0064: Fork pi-sticky-last-prompt locally to own its renderer internals, instead of npm patching, a companion extension, or upstreaming

Status: Accepted
Date: 2026-09-28

## Context

The fullscreen pin from npm `pi-sticky-last-prompt` v0.1.1 was wanted, but two local behaviors were not covered by it.
The bar drew a leading glyph from `PIN_ICON = "\uf007"`, commented `thumb_tack` upstream; U+F007 renders as the nf-fa-user person icon, which was unwanted.
Answers to `ask_user_question` were not reflected, because they are committed as tool results while the pin's anchor walker recognizes only `UserMessageComponent` and `SkillInvocationMessageComponent`.
The package reaches its behavior through private renderer internals: it takes the TUI from the `setWidget` factory, patches `handleSelectionMouseEvent` and `hasOverlay`, and walks the transcript component tree to derive document line offsets for pinning and click-to-jump.

Three local routes were weighed, none of them upstreaming such personal behavior.
The repo's `patches/apply.sh` library reapplies small diffs against a pristine upstream copy and refuses to run once upstream drifts; the icon change fit that shape, but pooling the answers changes the anchor walker and adds answer formatting, so the patch would have been feature-sized and rebased on every upstream bump.
A companion extension could pin the answer through the public `ctx.ui.setWidget()` API, but it renders above the editor rather than in the top bar, and it cannot reuse the pin's top overlay without duplicating its internals.

[ADR-0062](0062-session-naming-in-own-extension.md) chose a tracked extension over "a fork, a local package" for session naming, but that was different ground: naming could be done entirely from the public extension surface, while the pin's top overlay and scroll-offset anchoring are not exposed.

The base scroll step was also wanted faster, since the renderer defaults `wheelScrollLines` to 1 and one wheel notch or trackpad tick moved a single line.

## Decision

The pin is a tracked local fork at `agent/extensions/sticky-last-prompt/index.ts`, and `npm:pi-sticky-last-prompt` is removed from `settings.json`; the file header lists the local changes.
Those changes drop the leading icon, and record an `ask_user_question` tool result as an anchor in the same walk that records typed prompts.
The result is identifiable because its `ToolExecutionComponent` carries an own `toolName` property, and the answer is formatted from that component's `result.details`, so the bar treats an answer exactly like a prompt: hidden while visible, pinned once scrolled off, and jumpable on click.

`agent/extensions/faster-scroll.ts` sets the renderer's private `wheelScrollLines` to 3 through the same `setWidget` handle, leaving the hardcoded Alt+wheel multiplier on top of it.

Neither change is recorded in `patches/apply.sh`; the fork is the record.

## Consequences

No `pi update` path touches the pin, so upstream fixes and features are merged by hand or not at all.
The harness owns roughly four hundred lines of private-internals code, where a pi renderer rename can silently break the overlay, the offset walk, clicking, or the wheel field without raising an error.
The answer text is read from the tool result's private `details` shape, so a change to it would silently drop the answer anchor and fall the bar back to typed prompts.
The `patches/apply.sh` library stays the route for third-party code that cannot move into the harness, as in [ADR-0057](0057-omarchy-bugfix-patch-steps.md).
The fork is dropped and this record superseded if upstream exposes a stable overlay or anchoring API.

