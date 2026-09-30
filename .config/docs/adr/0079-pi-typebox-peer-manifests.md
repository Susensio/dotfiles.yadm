# ADR-0079: Silence Pi's host-provided-dependency warning by patching the four extension manifests to peerDependencies, instead of deleting the duplicate typebox copies or waiting for upstream

Status: Accepted
Date: 2026-09-30

## Context

Pi 0.99.1's extension loader began warning at startup when an extension manifest declares a host-provided package in `dependencies`.
Pi supplies `typebox` (and aliases the legacy `@sinclair/typebox` name), and [the package docs](https://github.com/earendil-works/pi/docs/packages.md) require those packages in `peerDependencies` with a `"*"` range.
Four installed extensions violated it: `@juicesharp/rpiv-ask-user-question`, `@juicesharp/rpiv-todo` and `@juicesharp/rpiv-web-tools` declared `typebox`, and `@tintinweb/pi-subagents` declared both `typebox` and `@sinclair/typebox`.
The warning named all four on every start and on every `pi` invocation that loads extensions; `pi --offline < /dev/null` reproduced it exactly.

Upstream already tracked the bug and had not shipped a fix in the installed releases (`rpiv-*` 2.11.0, `pi-subagents` 0.19.0): [rpiv-mono #266, #269, #270, #271, #272, #276, #277](https://github.com/juicesharp/rpiv-mono/issues?q=typebox) and PRs #267/#269/#271, and [pi-subagents #358, #362, #366](https://github.com/tintinweb/pi-subagents/issues?q=typebox).
One of those threads had verified the workaround and the loader's alias table: `typebox`, `typebox/compile` and `typebox/value` — and the `@sinclair/typebox` equivalents — resolve to the host copy, so a physical copy never enables resolution; it only duplicates it.
The four packages import only those aliased specifiers.

Alternatives were weighed.
Waiting for upstream removes the work with no ship date.
Deleting `node_modules/typebox` and `node_modules/@sinclair/typebox` matches Pi's intent completely, but `package-lock.json` still declares them for `@juicesharp/rpiv-config`, so the next `npm install` restores them and the delete would need its own postinstall step fighting npm every time.
Patching only the manifests satisfies the check Pi actually performs.

## Decision

Four patches in the existing patch library ([ADR-0066](0066-trust-auto-reviewer-external-directory.md) mechanism) each moved the host-provided package(s) from `dependencies` to `peerDependencies` with a `"*"` range: `pi-rpiv-ask-user-question-typebox-peer`, `pi-rpiv-todo-typebox-peer`, `pi-rpiv-web-tools-typebox-peer` and `pi-subagents-typebox-peer`.
They are reapplied by the same `postinstall` hook (`patches/reapply-all.sh`) that runs after every install, so a package update returns to a warned state only until the hook runs.

The physical copies were left in place deliberately.
Pi's check reads the manifest, the alias table shadows the copies at runtime, and the patches change no import, so deleting the copies would buy nothing the warning gate measures.
`@juicesharp/rpiv-config` also declares `typebox`, but it carries no `pi` manifest, so it is never warned and stays unpatched.

Each patch's `marker` is `"typebox": "\*"` (or `"@sinclair/typebox": "\*"`): `apply.sh` greps it as a basic regex, where an unescaped `*` would also match the pristine `"typebox": "^1.1.24"` line and report a false "already applied".

## Consequences

Startup is warning-free; the reproducer (`pi --offline < /dev/null`) printed the four warnings before the patches and nothing after, and an RPC-mode start still registered the extensions' status sources with no `ERR_MODULE_NOT_FOUND`.
The patch is a manifest declaration change only, so no code path moved.

Accepted limitations:

- The duplicate `typebox` (1.3.34) and `@sinclair/typebox` (0.34.52) copies, their lockfile entries and their version drift from the host copy remain on disk. Only the declaration Pi checks is corrected; the warning was the whole of the visible problem.
- The four packages became `patches/*/target` entries, so the [ADR-0067](0067-bundle-pi-extensions.md) screen now refuses them at gate P. `pi-subagents` was already refused; the three `rpiv` packages previously carried `skip` verdicts and none was bundled, so startup cost is unchanged.
- Pi's check is manifest-shaped, so a future release that also inspects resolved modules would surface the copies this record leaves in place.

Drop the patches when upstream ships the `peerDependencies` fix (rpiv-mono #267/#269/#271, pi-subagents #358/#362/#366); `apply.sh` reports drift against the kept pristine manifest rather than patching a newer release silently.
