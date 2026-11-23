# ADR-0128: Patch remote-pi's host dependencies to peerDependencies like ADR-0079

Status: Accepted
Date: 2026-11-23

## Context

Installing `remote-pi` 0.7.0 produced a warning on every `pi` start — it declared `@earendil-works/pi-coding-agent`, `@earendil-works/pi-tui` and `typebox` in `dependencies` rather than as `"*"` peers, the exact failure ADR-0079 solved for four other packages. The install also brought its own 0.79.10 copies of the pi runtime into the extension tree while the host pi is 1.5.2; the warning is manifest-shaped, so satisfying it does not remove those copies from disk. Leaving the warning would normalize startup noise that ADR-0079 deliberately eliminated.

## Decision

Add `pi-remote-pi-typebox-peer` to the existing patch library: move the three host-provided packages from `dependencies` to `peerDependencies: "*"` in remote-pi's manifest, with a marker of `"@earendil-works/pi-coding-agent": "\*"` — escaped, because apply.sh treats the marker as a basic regex and a bare `*` would also match the pristine `^0.79.10` line and report a false "already applied". The standard reapply-all hook applies it after each install.

## Consequences

`pi --offline </dev/null` is warning-free again, and a simulated reinstall (restore pristine manifest, run reapply-all) reproduces the patched result. Accepted limitations: the duplicate 0.79.10 pi-runtime directories and the lockfile entries remain; as in ADR-0079, the loader's alias table shadows them at runtime and the check that produced the warning is manifest-shaped. A future remote-pi release that declares these as peers makes the patch a no-op, and rebase drift will report it for deletion.
