# ADR-0071: Ask in the agent's pane before every pkexec, instead of a focus-wait wrapper or a Pi gate extension

Status: Accepted
Date: 2026-09-29

## Context

Agents ran root commands through `pkexec`, whose polkit dialog took the fingerprint; `sudo` was already denied in Pi because its fingerprint prompt waited invisibly in the agent's pipes.
The dialog opened the moment the agent ran the command, so an operator looking elsewhere met a fingerprint prompt without the command that caused it, or missed it.
The wanted shape was: the dialog opens only when the operator is at the agent's window.

In Claude, `Bash(pkexec *)` had just been added to `permissions.allow`, so pkexec ran unasked.
In Pi, `pkexec *` was already `ask`, but every ask went first to the auto-review authorizer ([ADR-0066](0066-trust-auto-reviewer-external-directory.md)), which may allow a bash ask on the operator's behalf; only its `defer` reaches the operator.

Four routes were weighed.
A pkexec wrapper that held the call until the agent's herdr pane and Hyprland window were both focused needed one step instead of two, but it had to map a pane to a window through the multiplexer, and an agent calling `/usr/bin/pkexec` bypassed it.
A small Pi extension on `tool_call`, modelled on Pi's shipped `permission-gate` example, would have asked deterministically; the operator preferred a config-only change.
Removing auto-review would have sent every routine ask back to the operator.
A human ask inside each harness reused what both already had: the prompt shows the full command in the pane, and herdr marks the pane as waiting.

## Decision

Every pkexec is preceded by a human ask in the agent's own pane; answering it is what puts the operator in front of the fingerprint dialog.

- Claude: `Bash(pkexec *)` is a `permissions.ask` rule, which Claude Code evaluates before the auto-mode classifier and always prompts; `sandbox.excludedCommands` lists `pkexec`, since the sandbox strips setuid.
- Pi: `pkexec *` stays `ask`, and the auto-reviewer's `additionalPolicy` says any command running pkexec is always deferred to the user and never allowed.

## Consequences

Each privileged command costs two steps, a key in the pane and then a finger.

Pi's gate rests on the reviewer model obeying its policy; a reviewer that allows a pkexec ask anyway opens the dialog unannounced, still behind the fingerprint.
The Pi extension route stays the deterministic fallback if the review log ever shows a pkexec ask decided by the authorizer.

`sandbox.excludedCommands` matches a bare command name, so a pkexec line carrying a redirection is not excluded and fails inside the sandbox; privileged writes use `pkexec install`, `pkexec tee` or `pkexec sh -c` instead.
