# ADR-0130: Document that phone prompts cannot approve desktop permission asks

Status: Accepted
Date: 2026-11-23

## Context

Remote Pi 0.7.0 forwards phone messages as user turns to a local Pi process, but its `approve_tool` handler is an explicit no-op: the approval gate was removed upstream and the message type is kept only for forward compatibility. The desktop's permission system still asks — this setup's chain is `session-yolo → always-ask → auto-review` with `"*": "ask"` and a reviewer for anything the rules do not settle. A phone-driven turn that reaches such an ask therefore waits at the TUI, with no way for the phone user to resolve it. The `@eko24ive/pi-ask` bridge is separate: it renders clarification questions natively on the phone, not permission dialogs.

Daemon mode does not solve this in this setup: its headless RPC sessions cannot open pi-ask's TUI questionnaire (`ctx.mode !== "tui"` returns a cancelled result), and there is no phone approval path either.

## Decision

Treat interactive TUI sessions as the only supported phone-control mode for now, and leave the permission chain untouched. Do not put a `yoloMode` or blanket allow rule in the shared permission config just to make phone prompts unattended — that would remove the gate from every desktop session too.

## Consequences

A phone user must avoid operations that reach the reviewer, or an interactive desktop user must approve them. `/yolo` can be enabled per session when unattended operation is wanted and accepted; it is in-memory and session-scoped. If remote-pi later ships a real approval wire contract, revisit this record and consider daemon mode again.
