# ADR-0062: Name sessions from a tracked extension instead of patching the naming package, a fork, a local package, or a watcher

Status: Accepted
Date: 2026-09-28

## Context

Sessions had no name, so the `pi-footer` statusline and the `/resume` picker fell back to a truncated first prompt.
Auto-naming was wanted, and the published namers did not work on this provider.
opencode gateways reject a side call without `x-opencode-session`, and the namers made those calls through the model registry, which sent no session id: the request failed with `400 MissingSessionID` and resolved with empty content, so the failure was silent.
`pi-session-name` built the header by hand and named sessions, but it put its whole title instruction in the system prompt, which opencode-go drops, so the model answered the prompt and the session took its name from the answer's first sentence.
The header gap was already half fixed upstream: pi-ai maps `options.sessionId` to the header since 0.87.1 ([#9326](https://github.com/earendil-works/pi/issues/9326), closed), while the extension surface still passes no session id, which is filed as [#9290](https://github.com/earendil-works/pi/issues/9290) and [#10053](https://github.com/earendil-works/pi/issues/10053), both closed not planned.

With the fix small either way, the decision was where it should live.
Patching the npm package meant the next `pi update --extensions` would rewrite the file, and every trigger to reapply it had a gap.
pi installs packages with `npm install <pkg> --prefix <agent npm directory> --legacy-peer-deps`, and npm runs no lifecycle script for the prefix project, with `ignore-scripts` false and a working `postinstall` confirmed in a plain project.
pi raises no package-install event, dependency install scripts are gated by npm's allow-scripts, and pi rewrites the dependency list from its settings on each install.
A systemd path unit on npm's lockfile, a `session_start` extension, or a `pi` wrapper would each work while adding a mechanism whose failure mode is quiet.
A fork or a local package avoided the rewrite by owning the code, at the cost of vendoring a third-party extension.

The adjacent case was already ruled on: ADR-0057 patches an Omarchy system file from a bootstrap step, one step per upstream PR.
That rule covers files no user config can shadow, which is not this one.

## Decision

Session naming lives in a tracked extension, `agent/extensions/session-name.ts`, which pi auto-loads, rather than in a patched package.
It names a session from its first prompt on `agent_end`, pins `opencode-go/gpt-6-luna` for the title and falls back to the session model when that model is outside the session's model scope, leaves a hand-set `/name` alone, and passes `sessionId` on the model call so the gateway accepts it.
One-shot runs are named as well as TUI sessions.

Only the package side was reported, as a request to pass the session id the same way: its repository's own conventions call for the model call to carry it rather than for an extension to build the header.
Nothing was filed against pi, whose remaining gap those closed reports already carry.

## Consequences

Nothing rewrites the file, so there is no patch entry, reapply hook, watcher, or fork to maintain, and no rebase when the package or pi moves.

The harness owns roughly eighty lines that upstream packages may later do better, the title prompt and the session id included.
Each session costs one extra model call, outside the footer's totals.

The extension is deleted once a naming package passes a session id and keeps its instruction where the provider reads it.
ADR-0057's patch-step pattern stays the route for third-party code that cannot move into the harness.

