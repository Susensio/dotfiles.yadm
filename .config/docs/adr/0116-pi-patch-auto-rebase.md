# ADR-0116: Three-way rebase a drifted patch onto the new upstream file in the library, instead of stopping at a manual-rebase warning

Status: Accepted
Date: 2026-11-20

## Context

`apply.sh` applies a patch only to a byte-identical pristine target, on purpose: npm updates land silently and some of these patches touch permission code, so a patch fitted to an approximate file is exactly what that guard exists to refuse.
The refusal was also the end of the road.
A package update moved the file, `apply.sh` warned "target no longer matches the kept pristine copy … then refresh the .orig and regenerate the patch", and the rebase was hand work done when someone noticed the warning ([ADR-0101](0101-cd-home-prefix-patch.md), [ADR-0112](0112-harness-updates-are-deliberate.md) recorded two such rebases).
Until then the patched behaviour was simply absent, which for `pi-permission-cd-home-prefix` means the external gate names a path the shell never reaches ([ADR-0101](0101-cd-home-prefix-patch.md)).

The library already holds everything a rebase needs: a pristine `.orig` of the version the patch was written against, and the patch itself.
`git merge-file` takes exactly that shape — a new upstream file, the base `.orig`, and the patched form — and reports a clean merge by exit status, with conflict markers and a conflict count when the two changed the same region.
The patch's own patched form is likewise reproducible: applying it to the `.orig` in a scratch directory is what `apply.sh` does to the real target.

Alternatives weighed: leaving the warning as the whole mechanism; a `patch --merge` variant, whose conflict output names neither the base nor the patch and drops the hunk into a `.rej`; rebasing on every `apply.sh` invocation whether or not the file drifted; writing the conflict-marked merge into `node_modules` so a diff shows it.

## Decision

Add `patches/rebase.py`, which rebases one patch and is run by `reapply-all.sh` before `apply.sh` for each patch whose target is not pristine.
It materializes the patched form from `.orig` in a scratch directory, three-way merges it into the live target, and on a clean merge refreshes `.orig` from the new upstream file and regenerates `.patch` from the merged result, so the next run is byte-identical again.
A new `base` file records the package version and release the refreshed `.orig` now tracks, which is the fact the ADR-cited release name stops carrying once a patch rebases.

A conflict changes nothing: the target keeps its pristine upstream contents, so the extension still loads, and the script warns naming the file to rebase by hand.
Files the patch creates are rewritten only when absent, or when present and byte-identical to the patch's own copy — a release that ships a different file at that path is reported as a possible upstream landing instead of being overwritten.

The successful-rebase line is tagged `rebased:` because `mise/tasks/pi-postinstall` treats any other output from `reapply-all.sh` as a patch needing attention and fails the install ([ADR-0112](0112-harness-updates-are-deliberate.md)); the task now filters that one tag and still fails on a conflict.
`apply.sh` is unchanged, so its byte-identical guard still decides whether a patch is applied; the rebase only decides whether the patch can fit.

## Consequences

A patch that a release moved now heals itself on the next install or interactive start, and the operator is told rather than asked.
A rebase that cannot merge still needs a person, but the message is now the only path that requires one.

The three-way merge can be silently wrong in a way `apply.sh`'s byte-identical guard cannot catch: if upstream rewrote the patched region to something semantically equivalent but textually different, the merge succeeds with the patch still applied on top, and the result compiles. `git merge-file` only refuses when the two edits overlap. Checking a rebase therefore still means reading the regenerated diff, which the `rebased:` line's version names; a patch whose upstream fix has landed should be deleted, not rebased ([ADR-0101](0101-cd-home-prefix-patch.md)'s drop condition), and the rebase does not detect that case.

The `.orig` no longer names the release the ADR cites, so `base` is the file to read for what a patch is now written against. A patch fitted to a release whose behaviour differs keeps applying until the merge conflicts, so the rebase buys time rather than certainty.

The script models one edited file plus created files. A patch that edits a second existing file, or deletes one, is reported instead of merged, since the `.orig` + `.patch` + `target` layout cannot express a pristine copy of a second file.
