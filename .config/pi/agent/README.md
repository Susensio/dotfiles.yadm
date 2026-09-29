# Pi harness: operating notes

This is the Pi-specific companion to [`docs/harness.md`](../../docs/harness.md), which explains the shared harness philosophy and the Claude/Pi/Codex boundaries.
[`../README.md`](../README.md) explains what yadm tracks and how to configure the Pi environment.
The live agent definitions, skills, extensions, and settings are authoritative for their own behavior; this file records only operational details that are easy to miss.

## Provider and permissions

An extension may make its own model call outside the main turn; `extensions/session-name.ts` does so for the first-prompt title and `/rename`.
It passes the session ID explicitly because opencode-go rejects headerless side calls, and places its instruction in the user turn because that gateway drops a bare system prompt.
See [ADR-0062](../../docs/adr/0062-session-naming-in-own-extension.md) for the decision to own the extension instead of patching a package.

The permission system asks by default and sends eligible requests to its auto-review authorizer; deferred requests still reach the human.
The authorizer calls `alias/reviewer` from `pi-model-fallback-alias` (chain in `model-alias.json`), so an exhausted Codex quota fails over to the OpenCode Go subscription instead of deferring every ask to the human.
Its last fallback, `claude-bridge/claude-haiku-4-5`, cannot actually serve: the bridge refuses system prompts it has not captured from a real session, and the reviewer sends the Guardian policy, so that target only bites if the bridge relaxes the rule.
The same file holds the `alias/top`, `alias/mid` and `alias/fast` tiers for session use; nothing points at them yet (see BACKLOG).
The `pi-model-alias-shared-registry` patch keeps the alias working after a subagent loads its own copy of the extension in the same process; delete it once [unrelentingfox/pi-model-fallback-alias#30](https://github.com/unrelentingfox/pi-model-fallback-alias/pull/30) ships.
Only provider failures advance the chain; a reviewer's `defer` verdict is final.
`models.json` registers `openai-codex/codex-auto-review`, which the authorizer otherwise synthesizes outside the registry where the alias cannot reach it.
Its hand-maintained rule and authorizer configs live beside their extensions.
For privileged commands use `pkexec`, not `sudo`: polkit opens a visible authentication dialog, while sudo's fingerprint prompt can wait invisibly in Pi's pipes and time out.
Use `pkexec /usr/bin/id -u` for a harmless root check, with a shell timeout of at least 60 seconds.
The auto-reviewer's policy defers every pkexec to you, so it waits in the pane's permission dialog and the fingerprint prompt follows your answer ([ADR-0071](../../docs/adr/0071-ask-before-pkexec.md)).

## Extension bundling

`bundler/` replaces screened packages' sources with esbuild bundles after every install, roughly halving startup ([ADR-0067](../../docs/adr/0067-bundle-pi-extensions.md)).
It is fragile: bundling changes module loading, not just file layout, and its gates catch only failure modes already seen — an approved bundle once deadlocked `ask_user_question`.
When an extension hangs or misbehaves, run `node bundler/bundle.mjs --revert` and retest before debugging the extension; `node bundler/screen.mjs` shows each package's gate and hazards.
`/bundle-review` measures each bundle's saving against source, reviews its hazards and verdicts, and proposes `verdicts.json` changes; run it after installing or updating a package.

## Validation boundaries

Run `/web-tools` once to configure search before using `web_search` or `web_fetch`.
`bash-readonly/` is loaded explicitly by the explorer and tester, not auto-discovered by the main session.
It uses Bubblewrap and unprivileged OverlayFS for a disposable writable view, but does **not** isolate the network; it requires Linux with unprivileged user namespaces and OverlayFS support.
When testing session-bound behavior, use a disposable session rather than attaching to a live one.
