# ADR-0101: Carry the permission system's cd home-prefix fold as a local patch until it ships upstream

Status: Accepted
Date: 2026-10-24

## Context

`pi-permission-system` 41.0.0 folded a literal current-shell `cd` into an effective base for the relative tokens after it, but treated a `~` / `~/…` target as non-literal: the base went unknown and the external gate resolved those tokens against the session cwd.
The ask therefore named a path the shell never reaches — `cd ~/.config/pi/agent/npm && sh ../../patches/reapply-all.sh` was judged as `/home/patches/reapply-all.sh` — and [ADR-0087](0087-licensed-external-directory-allow.md)'s remedy, an explicit `config.json` rule, cannot reach it: no rule matches a path that does not exist.

Three routes were weighed.
Avoiding `cd ~/…` followed by a relative path works and costs nothing, but it relies on an agent habit rather than on configuration, and the same shape reappears with the next model or the next session.
Waiting for a release keeps the friction for as long as the maintainer's queue is long.
Patching locally fixes the projection itself, at the price of a diff against security-relevant code.

The change is available: [gotgenes/pi-packages#1083](https://github.com/gotgenes/pi-packages/issues/1083) reports it and its PR folds `~` and `~/…` to `os.homedir()` plus the rest of the target, under the `HOME`-rebinding rule the token projection already applies.

## Decision

Add `pi-permission-cd-home-prefix` to the patch library in `pi/agent/patches/`, holding the pristine `bash-path-resolver.ts` of 41.0.0 and the fold as a unified diff.
`reapply-all.sh` and the bundler ([ADR-0067](0067-bundle-pi-extensions.md)) run from the npm project's postinstall, so an update re-applies the patch and rebuilds the bundle that pi actually loads.
The patched file is byte-identical to the PR branch, so the local behaviour is the code under review rather than a second implementation.

This is not a policy widening, which is why it does not contradict ADR-0087: the patch corrects which path the gate names, and the decision about that path still comes from `config.json`.
A rule remains unable to answer the same ask, so the patch is the only local mechanism that can.

## Consequences

Prompts for `cd ~/…` followed by a relative token stop after a `/reload` or a restart; the running session keeps the bundle it loaded.
The patch carries ADR-0087's own risk assessment for local patches: a buggy diff on a security boundary, maintained by hand.

Delete the patch directory once a release contains the fix.
The library reports the drop by itself: `apply.sh` warns that the target no longer matches the kept pristine copy, and `reapply-all.sh` surfaces that warning without failing the install, so a stale patch costs a message rather than a broken update.
If the upstream change lands in a different shape, delete the patch instead of rebasing it.
