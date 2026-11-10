# ADR-0111: Check the second bootstrap by what it changed and let steps warn about pending logins every run, instead of requiring it to print nothing

Status: Accepted
Date: 2026-11-10
Supersedes: [ADR-0056](0056-silent-idempotent-bootstrap.md)

## Context

[ADR-0056](0056-silent-idempotent-bootstrap.md) made every step check before acting and print only what it changed, and CI enforced that by failing the second bootstrap on any output.
The output was a proxy for the property that mattered, that a rerun changes nothing and never asks for privilege.
It failed in both directions: a step that mutated state quietly passed, and a step that reported state it could not fix failed.
The second kind arrived with the Tailscale step, whose "not logged in" warning printed on every run because a login needs a browser and CI never has one.
The warning was moved to `maintenance`, restored in the bootstrap, and then hidden behind a terminal check, which keeps CI green by dropping the warning from every unattended run, such as the one the post-update hook starts.

Logins had no common rule either.
The signing-key step ran `gh auth login` when stdin was a terminal and only warned otherwise, so the same step behaved differently under a hook, a pipe and a shell.
A step that starts a browser flow inside a bootstrap that other hooks run is one nobody sees prompt.
The homelab CA step called `sudo` with no terminal and aborted the whole bootstrap, skipping every step after it.

Checking output more cleverly was rejected: any rule about what a step may print has to tell a change from a status line, which is the judgement the check was meant to avoid.
Snapshots of everything were rejected too, since most state is already covered by two facts, no privileged call and no file written.

## Decision

The second bootstrap is checked by what it changed, in `yadm/bootstrap-rerun-check`, which all three CI jobs run in place of the silent-output check.
It fails when the rerun exits non-zero, calls `sudo` through a recording shim, writes a file under `$HOME` newer than a marker (minus caches, nvim's state and the bootstrap log), or leaves a snapshot different from before.
The snapshot lists what a step can change without either of those: Tailscale's preferences, enabled system and user units, installed packages and `/etc/sudoers.d`.
A step that changes other state gets an entry there, or its rerun goes unchecked.
What a rerun prints is not checked.

A step warns about state it cannot fix on every run, with the exact command that fixes it, and exits 0.
Steps never start a login or a refresh themselves, with or without a terminal: `gh auth login`, `gh auth refresh` and `tailscale up` are named in the warning and left to a person.
A step that needs `sudo` without a terminal warns with the command to rerun instead of failing, so later steps still run.
"Print only what you change" stays a style rule for steps, no longer a gate.

## Consequences

CI stops failing on a persistent warning, and the warning reaches `bootstrap.log` and `maintenance` from every unattended run instead of being dropped.
A step that mutates quietly now fails the check, which the output rule never caught.

The check only sees what it looks for.
State outside `$HOME`, the sudo calls and the snapshot is unchecked, such as a file under `/etc` rewritten without `sudo` by a root-owned helper.
The write check counts any file another process creates under `$HOME` during the rerun, so it suits CI and fails on a busy desktop.
Its first runs may name files a step legitimately rewrites, such as a tool's state directory, which then join the exclusions or the step is fixed.
Nothing has run it on a CI runner yet, and the sudo shim is untested under `as-dev` and `su --login`.

A warning on every run is noisier on a machine where the login is deliberately never done, and the bootstrap log keeps only the last run.
A new login-dependent step has to follow the rule by hand, as nothing enforces it.
