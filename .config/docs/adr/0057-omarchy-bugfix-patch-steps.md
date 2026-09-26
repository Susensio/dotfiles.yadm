# ADR-0057: Patch Omarchy system files from one bootstrap step per upstream PR, instead of overriding them from user config or waiting for the fix

Status: Accepted
Date: 2026-09-26

## Context

Omarchy's `default/hypr/envs.lua` put `/usr/share/omarchy/bin` first on the session `PATH`, ahead of `~/bin/overrides` and the `~/.local/bin` links from [ADR-0007](0007-link-mise-tools-into-xdg.md).
Its history showed a leftover: the prepend came with hot dev-link, which Omarchy later removed while making `env-bootstrap` prepend only in dev-link mode.
The fix belonged upstream, and a PR was drafted for it.

Until a fix ships, three local routes were weighed.
Overriding the result from our own `hypr/*.lua`, which Omarchy loads after its defaults, worked around the bug and kept it in the user config after the fix landed.
Waiting left the session broken for as long as the PR sat.
Editing `/usr/share/omarchy` by hand was lost on the next package update and left no record of why.

## Decision

A bug in an Omarchy system file with a PR submitted upstream is patched locally by a bootstrap step under `yadm/bootstrap.d/omarchy/bugfix/`, one step per PR, with the PR's diff as its asset ([ADR-0054](0054-bootstrap-helpers-in-libexec.md)).
Each step links its PR.
It does nothing when the reverse patch applies, meaning already patched or fixed upstream, and applies the patch with `sudo` only when the forward patch applies ([ADR-0056](0056-silent-idempotent-bootstrap.md)).
When neither applies, it warns that the patch is stale, so the PR can be checked and the step deleted.

## Consequences

A package update restores the unpatched file, so the fix is gone until the next bootstrap run; `yadm pull` runs one, and so does `omarchy update` through a `post-update.d` hook.
A step stays silent once the fix ships upstream, so it has to be deleted by hand when its PR merges.
A patch that no longer applies because Omarchy changed the file warns on every bootstrap until someone looks at it.

## Corrections

2026-09-26: the first Consequence said `omarchy update` did not rerun the bootstrap; a `post-update.d` hook added the same day made it do so.
