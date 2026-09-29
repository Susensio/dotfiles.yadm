# Pi harness: operating notes

This is the Pi-specific companion to [`docs/harness.md`](../../docs/harness.md), which explains the shared harness philosophy and the Claude/Pi/Codex boundaries.
[`../README.md`](../README.md) explains what yadm tracks and how to configure the Pi environment.
The live agent definitions, skills, extensions, and settings are authoritative for their own behavior; this file records only operational details that are easy to miss.

## Provider and permissions

Everything runs on the OpenCode Go subscription, without a second provider or model-fallback layer.
An extension may make its own model call outside the main turn; `extensions/session-name.ts` does so for the first-prompt title and `/rename`.
It passes the session ID explicitly because opencode-go rejects headerless side calls, and places its instruction in the user turn because that gateway drops a bare system prompt.
See [ADR-0062](../../docs/adr/0062-session-naming-in-own-extension.md) for the decision to own the extension instead of patching a package.

The permission system asks by default and sends eligible requests to its auto-review authorizer; deferred requests still reach the human.
Its hand-maintained rule and authorizer configs live beside their extensions.
For privileged commands use `pkexec`, not `sudo`: polkit opens a visible authentication dialog, while sudo's fingerprint prompt can wait invisibly in Pi's pipes and time out.
Use `pkexec /usr/bin/id -u` for a harmless root check, with a shell timeout of at least 60 seconds.

## Validation boundaries

Run `/web-tools` once to configure search before using `web_search` or `web_fetch`.
`bash-readonly/` is loaded explicitly by the explorer and tester, not auto-discovered by the main session.
It uses Bubblewrap and unprivileged OverlayFS for a disposable writable view, but does **not** isolate the network; it requires Linux with unprivileged user namespaces and OverlayFS support.
When testing session-bound behavior, use a disposable session rather than attaching to a live one.
