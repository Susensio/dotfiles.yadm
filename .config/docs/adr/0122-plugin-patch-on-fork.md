# ADR-0122: Carry a local plugin patch as a commit on the user's fork, with the clone's origin on it, instead of a bootstrap patch step

Status: Accepted
Date: 2026-11-22

## Context

Two carriers already exist for code that is fixed locally before upstream ships it.
[ADR-0057](0057-patch-omarchy-system-files-per-pr.md) patches an Omarchy system file from a bootstrap step, one step per PR, applying a diff idempotently under `sudo`.
The [Omamail patch](../STATE.md) instead edits a plugin clone's working tree and reverts the edit before each update.

`omarchy plugin update` runs `git fetch origin HEAD` and then `git merge --ff-only FETCH_HEAD`.
A clone therefore updates only onto a ref that already contains its local commit, so any committed local fix on `origin` fails the merge outright, and only an uncommitted working-tree edit survives — after being reverted and re-applied by hand, which is why the Omamail entry carries that instruction.
[ADR-0072](0072-omarchy-plugin-source-declaration.md) recorded this as an accepted consequence: *"Plugin updates retain their own git history and local edits; `omarchy plugin update` may still conflict with an uncommitted local patch."*

A patch step fits a root-owned package tree, which has no repository to point at and is restored on every package update.
It fits a plugin clone poorly: the fix becomes a diff that rots whenever upstream touches the file, the clone carries an uncommitted edit nobody can see in its history, and every update needs the revert dance.
The speaker calibrator's fix was 70 lines rewriting a control path with tests ([thefreshoffice/omarchy-speaker-calibrator#42](https://github.com/thefreshoffice/omarchy-speaker-calibrator/pull/42)), which is a poor diff and a good commit.

## Decision

A local fix to a plugin clone is carried as a commit on the user's fork of that plugin, and the clone's `origin` is the fork, so `omarchy plugin update` fetches a ref that already contains the fix and fast-forwards onto it instead of failing.
Upstream stays attached as a second remote named `upstream`, and the fork's `main` holds the fix.
The branch sent as a pull request's head is the same commit, so the deployed tree and the submitted tree cannot diverge.
This narrows [ADR-0072](0072-omarchy-plugin-source-declaration.md)'s accepted consequence: a fork-carried patch is a pushed commit, not a working-tree edit, so the revert-before-update instruction no longer applies to it.
[ADR-0057](0057-patch-omarchy-system-files-per-pr.md) continues to govern Omarchy system files.

`maintenance` reports every forked clone that has fallen behind `upstream`, and every one whose patch is already upstream by patch identity, with the command that rebases or retires it.

## Consequences

The fix has a message, a diff and a PR link in the clone's own history, rebases mechanically when upstream moves, and never blocks an update.
Patches on a clone this arrangement has not been applied to still behave as ADR-0072 described.

A fork is state someone must retire by hand, and the `upstream` remote is what makes it recognisable: a forked clone with no patch commits left has shipped its fix and should be reset to `upstream` and dropped, which `maintenance` points at rather than doing.
A fork can also drift silently if it is never looked at, which is why the drift report is part of this decision rather than a convenience.

A fresh machine still installs the unpatched plugin, because `plugins.conf` records the upstream URL, so a rebuild loses the fix until the PR merges.
Declaring the fork instead would fix that at the cost of a declaration to revert later; not done yet.

Deleting the fork is manual and nothing automated points at it once the patch lands, beyond the maintenance finding named here.

## Corrections

2026-11-22: the record was first committed scoped to the speaker calibrator's clone alone, as a remote-layout note for one pending PR.
It was widened the same day to the standing rule for plugin clones, and the drift report it names became part of the decision rather than a convenience.
