# ADR-0066: Trust the auto-reviewer with the external_directory family by patching the delegation envelope, instead of widening static external allows or waiting for upstream

Status: Accepted
Date: 2026-09-28

## Context

The permission system's bounded-delegation checkpoint capped every authorizer-chain link's `allow` on the whole `path` and `external_directory` families to `defer` ([upstream ADR 0007 §5](https://github.com/gotgenes/pi-packages/blob/main/packages/pi-permission-system/docs/decisions/0007-model-judge-authorizer-chain-adr.md)).
With the Codex-style auto-reviewer the only registered link, no outside-CWD ask could be approved by it, so every one reached the operator.

The review log showed the result as a hard split: in one window, all ten `external_directory` / `external_directory_read` dialogs were user-decided, while the reviewer decided 167 other asks.
The usual trigger was reading distribution files (`/usr/share/omarchy`, `/usr/bin`, `/usr/lib`) with a command outside the pure-reader core — `sed`, `strings` — because an unproven direction consults both directional surfaces, the write side asks, and the checkpoint then forced the operator prompt for what was in fact a read.

Three routes were weighed.
Widening `external_directory` in `config.json` silences the prompt with no review at all, and the auto-reviewer itself rejected a broad `/usr/*` write allow as weakening a boundary the operator had asked to keep under review.
Waiting for upstream [#620](https://github.com/gotgenes/pi-packages/issues/620) and its reference implementation [#983](https://github.com/gotgenes/pi-packages/pull/983) (`authorizerTrust`) kept the friction with no ship date.
A local patch of the checkpoint kept the model deciding exactly the asks the operator did not want to see.

## Decision

Patch `DELEGATION_EXCLUDED_SURFACES` in the permission system's `src/authority/delegation-envelope.ts` to exclude only the `path` family, so the auto-reviewer's `allow` on `external_directory` — the bare family and both directional members — stands instead of being downgraded to `defer`.
The patch is one line of code plus a marker comment naming this record, and it lives in the `patches/apply.sh` library as `pi-external-directory-trust` so it can be re-applied after a package update.

Re-application is wired rather than remembered.
The library's `reapply-all.sh` is the `postinstall` script of the pi npm project (`pi/agent/npm/package.json`), so the npm install behind `pi install` and `pi update --extensions` re-applies every patch in the same command; it stays silent when nothing changed and warns rather than failing, so a stale patch never breaks an install.
That file belongs to pi and yadm does not track it, so the hook line is injected by a bootstrap step in the [ADR-0057](0057-omarchy-bugfix-patch-steps.md) shape, which also applies the library.
Where pi has never run, the step creates the npm project itself — pi's own `{name, private}` stub plus the hook — so pi's first-start auto-install of the packages in `settings.json` already carries the hook and applies the patch in that same start; afterwards the step repairs the hook if pi regenerates the file.
The library itself is tracked by yadm, so a fresh clone carries the patch and its tooling.

The `path` family stays capped, so secret denies and the `path_write` checkpoint on the permission config still cannot be auto-approved.

The auto-reviewer's `additionalPolicy` was extended in the same change, because the envelope alone would have moved the friction rather than removed it: that policy called only the project, `/tmp`, and `~/.config` routine, so the reviewer would have deferred a `/usr/share/omarchy` read straight back to the operator.
Reading system and distribution files for inspection is now routine there, and defer is reserved for writes outside those trees.

## Consequences

Outside-CWD asks are decided by the model reviewer instead of the operator, and the operator keeps the prompt only for `path`-family asks and for whatever the reviewer defers.

The checkpoint's guarantee is weaker by one family: a buggy or over-eager reviewer can now approve access outside the working tree that no config rule grants.
The `path` denies are unaffected — the path gate runs first, so a secret named there is refused before the chain is consulted — but an external path with no matching rule is within the reviewer's grant.

The hook lives in `pi/agent/npm/package.json`, which pi owns: npm preserves a `scripts` key when it rewrites that file, and the bootstrap step re-injects the line if a pi release regenerates it, but a failing `npm install` skips `postinstall` altogether and the step runs only on a bootstrap, so the patch can still lapse unnoticed.
The symptom is only the return of operator prompts, not a widened policy.

`apply.sh` itself needed a fix to apply anything at all: its `patch … < "$dir"/*.patch` relied on pathname expansion of a redirection word, which POSIX does not require of a non-interactive shell and which the system's `/bin/sh` (bash in POSIX mode) does not perform, so the library had never worked when executed directly.
It now expands the glob into a variable first.

The patch is deleted once [#983](https://github.com/gotgenes/pi-packages/pull/983) or [#620](https://github.com/gotgenes/pi-packages/issues/620) ships an equivalent, operator-controlled capability upstream.
