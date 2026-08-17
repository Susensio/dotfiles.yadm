# ADR-0005: Make the yadm bootstrap idempotent and directory-dispatched

Status: Accepted
Date: 2026-06-02

## Context

The system patches from [ADR-0004](0004-xdg-compliance-via-patching.md)
live outside package management, so `apt` upgrades to `bash` or `lightdm`, or
a fresh install, can revert them. Bootstrap has to be safe to run again at any
time to restore that state, not just once on a new machine.

## Decision

`yadm/bootstrap` dispatches every executable file under `bootstrap.d/`
(excluding `*##*`), sorted by name, adapted from yadm's own contrib
`bootstrap-in-dir` script. The executable bit is the enable/disable switch;
numeric prefixes (`00_dependencies.sh`, ...) fix run order. Each script guards
its own idempotency: `00_dependencies.sh` only installs packages `command -v`
can't already find; `xdg_compliance/bash.sh` checks with `grep --quiet`
before appending its patch, and installs assets with
`sudo install --mode ... --compare -D`, which is a no-op when the file
already matches.

## Consequences

Bootstrap can be re-run after any upgrade or on a fresh machine to restore
the intended state, and individual steps can be disabled by removing the
executable bit rather than deleting code. Trade-off: idempotency is a
convention each script has to implement itself — a missing guard, or a step
that isn't `--compare`d, corrupts state on a second run instead of being
caught structurally. There's no rollback path either, only re-apply.

