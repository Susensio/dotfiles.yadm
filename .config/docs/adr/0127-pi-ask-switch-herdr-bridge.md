# ADR-0127: Keep the herdr ask bridge on pi-ask's lifecycle events after switching ask tools

Status: Accepted
Date: 2026-11-23

## Context

Remote Pi — the mobile control extension — renders only `@eko24ive/pi-ask`'s `ask_user` flows natively on the phone; the previously installed `@juicesharp/rpiv-ask-user-question` degrades to plain chat there. Running both tools at once was worse than either: two near-identical "ask when ambiguous" tools with competing prompt guidelines, and the model guessing which to call. The user found pi-ask's terminal interface equivalent, so the switch cost nothing in the TUI.

ADR-0060's bridge existed because rpiv emits a dedicated blocked channel (`rpiv:ask-user:blocked`) that herdr's pi integration did not listen for; the bridge forwarded it to the `herdr:blocked` event herdr actually consumes. pi-ask has no blocked channel — it emits `@eko24ive/pi-ask:started` and `:completed` around each flow, and only `dispose` (session shutdown) skips `completed`; submit and dismiss both end in `maybeFinish`, which emits it. ADR-0060's decision to automate herdr integration installs stands; only its premise about which channel the bridge forwards changed. Alternatives: dropping the bridge entirely would leave herdr's pane stuck on `working` while a question waits (the original ADR-0063 failure); having herdr consume pi-ask's channels natively is upstream work tracked in BACKLOG and not shipped.

## Decision

Switch the ask tool to `@eko24ive/pi-ask` and remove `@juicesharp/rpiv-ask-user-question`. The bridge extension stays and now forwards `@eko24ive/pi-ask:started` → blocked-active and `@eko24ive/pi-ask:completed` → blocked-inactive, tracking open flow ids so concurrent flows cannot clear each other's state, and clearing them on `session_shutdown` because pi-ask disposes flows there without emitting `completed`.

`pi-permission-system`'s allowlist names tools explicitly, so `ask_user` replaces `ask_user_question` there; without the swap every question would have fallen through to the `"*": "ask"` reviewer gate. `sticky-last-prompt`'s pooling records pi-ask's `details.answers` (labels + customText, plus note) instead of rpiv's `answers[]` array. `@eko24ive/pi-ask` carries a bundler `skip` verdict: it resolves its configuration doc through `import.meta.url`, which inlining would break, and its 14 ms source import is far under the bundle bar.

## Consequences

Questions render natively in the Remote Pi mobile app while keeping the terminal interview, and herdr's pane state stays truthful through answer and cancel paths (both verified headlessly). The phone's remote submit and the terminal dialog answer the same flow, so answering on one surface closes the other.

Accepted limitations: the ADR-0060 premise — that the bridged channel is `rpiv:ask-user:blocked` — no longer describes the live bridge; this record supersedes it, and the BACKLOG item now asks herdr upstream for pi-ask's lifecycle channels. pi-ask's `/answer` extraction calls a model configured in `~/.pi/agent/extensions/eko24ive-pi-ask.json`; that config is unset and the feature is unused here so far. The bundler still lacks a verdict for `@tintinweb/pi-subagents` 0.26.1, a staleness that predates this switch and is untouched by it.
