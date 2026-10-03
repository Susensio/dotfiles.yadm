# ADR-0081: Give Pi a session-only yolo and a deterministic always-ask list as own authorizer links, instead of the shared yoloMode or the reviewer's pkexec policy

Status: Accepted
Date: 2026-10-03

## Context

`yoloMode` in `pi-permission-system` 36.2.0 was config-file only, and every session re-read that file each turn, so turning it on for one session turned it on for every running pi.
It also rewrote asks to allows before the authorizer chain ran, which is how a `yay --sudo pkexec` call opened polkit unannounced and why yolo was off ([ADR-0071](0071-ask-before-pkexec.md), 2026-10-01 correction).
The Pi half of ADR-0071 rested on the auto-reviewer's `additionalPolicy`, but the reviewer could only answer allow or deny, so a pkexec ask was denied rather than put to the operator.

The package's one extension point was a named `authorizerChain` link registered through `registerAuthorizer`.
A link's verdict is allow, deny, or defer to the next link, and a subagent's asks run on the parent's chain.
A configured name with no registered link is skipped with a one-time warning, so a link that fails to load means more prompting rather than less.
The delegation envelope caps a link's `allow` on the `path` family to `defer`; [ADR-0066](0066-trust-auto-reviewer-external-directory.md) had already lifted the cap on `external_directory`.

Alternatives weighed: waiting on upstream `gotgenes/pi-packages#720`; patching `yoloMode` into session state; one extension doing both jobs; two independent links.
One extension fails closed as a unit, while two can fail apart: with yolo ahead of a missing always-ask, pkexec would go through.
Two independent links were chosen, each unaware of the other, so the chain's first-decider-wins order is the only thing that decides between them and stays predictable.
A variant where yolo deferred on the always-ask list was built and dropped for coupling the links.

## Decision

Two local extensions register chain links, configured as `authorizerChain: ["session-yolo", "always-ask", "auto-review"]`:

- `session-yolo` holds an in-memory switch, toggled by `/yolo` or set at launch by `--yolo`; on, it allows every ask that reaches it; off, it defers everything.
- `always-ask` puts any bash ask whose command matches the list to the operator with a confirm dialog and returns that answer as final; it defers everything else, and defers without a UI.

The list is `always-ask.json` in the agent directory, globs over the whole command, holding `*pkexec*`; only `always-ask` reads it.
Both links read the package's process-global service map directly, because the package is not resolvable from a local extension.
`yoloMode` stays `false`, and the reviewer's pkexec clause stays as a fail-closed fallback for when `always-ask` is not loaded.

## Consequences

Yolo became per session and per process: nothing is written, `/new` or `/resume` turns it off, and `--yolo` turns it back on.
`session-yolo` runs first by choice, so under yolo pkexec is approved too and polkit opens without a pane prompt; swapping the two keeps the prompt under yolo.
With yolo off, a pkexec ask now reaches the operator instead of being denied by the reviewer.
The always-ask dialog is the extension's own confirm, not the permission dialog: it has no "for this session" option, and the review log records the decision as made by the `always-ask` authorizer rather than by the user.
It drives herdr's waiting marker itself through `herdr:blocked`.
Matching the whole command also prompts for commands that only mention pkexec, such as a search for the word.
Yolo cannot silence `path`-family asks, so the browser-profile asks still prompt, and a listed command arriving on that family is capped back to the reviewer, which denies it.
Sessions started before the config change warn once about the two unregistered names until they `/reload`.
The service-map key is an internal of the package; if it moves, both links silently fail to register, which falls back to prompting.
