# ADR-0122: Point a patched plugin clone's origin at the user's fork so plugin update fast-forwards, instead of reverting the patch before each update

Status: Accepted
Date: 2026-11-22

## Context

The speaker calibrator plugin needed a local fix while its upstream PR was open ([thefreshoffice/omarchy-speaker-calibrator#42](https://github.com/thefreshoffice/omarchy-speaker-calibrator/pull/42)).
[ADR-0072](0072-omarchy-plugin-source-declaration.md) already accepted the resulting friction as a consequence of leaving plugin clones untracked: *"Plugin updates retain their own git history and local edits; `omarchy plugin update` may still conflict with an uncommitted local patch."*

`omarchy plugin update` runs `git fetch origin HEAD` and then `git merge --ff-only FETCH_HEAD`.
Any local commit that `origin HEAD` does not contain therefore cannot fast-forward, and the update fails with *"cannot fast-forward; you have local changes"*; only an uncommitted working-tree edit survives, and only after being reverted first, which is what the Omamail patch does (`git checkout -- manifest.json`, recorded in [STATE](../STATE.md)).

Three routes were weighed for a patch that must stay live until its PR merges.
The [ADR-0057](0057-patch-omarchy-system-files-per-pr.md) mechanism applies a bugfix step's patch under `yadm/bootstrap.d/omarchy/bugfix/`, which is how Omarchy's own system files are patched; pointed at a plugin clone it leaves the fix as an uncommitted working-tree change, so the same revert-before-update dance returns and no clone records who patched it.
Reverting the patch before every update keeps the clone on upstream but makes the machine silently lose the fix whenever someone updates and forgets to re-apply.
Committing the fix to the clone's own branch while `origin` stays upstream cannot fast-forward at all, which is the ADR-0072 consequence verbatim.

## Decision

For a plugin carrying a local fix that awaits an upstream PR, the clone's `origin` is the user's fork of that plugin and the fork's `main` holds the fix, so `omarchy plugin update` fetches a ref that already contains the local commit and fast-forwards onto it, reporting *"up to date"*.
Upstream stays attached as a second remote named `upstream`, and `origin/main` tracks the fork, so the fix is a normal pushed commit rather than a working-tree edit.

The patch is developed on a branch with the same commit that goes to `origin/main`, so the pull request's head and the deployed state are the same tree.

## Consequences

Updates stop failing on this plugin: they either report up to date or fast-forward, and the patch is a commit with a message and a PR link rather than an anonymous local edit.
The fix reaches a fresh machine only after its PR merges, because [ADR-0072](0072-omarchy-plugin-source-declaration.md)'s `plugins.conf` records the upstream URL and bootstrap clones from that; until then another machine gets the unpatched plugin.
The fork's `main` now needs syncing: after the PR merges, reset it to `upstream/main` and push, or rebase the fix onto a newer `upstream/main` if a release intervenes.
Deleting the fork later is a manual step with no record pointing at it, so the tracked state for the patch has to name it.
This deviates from the ADR-0057 bugfix-step convention for Omarchy system files; that convention still governs them, since they are not git clones anyone can point at a fork.
