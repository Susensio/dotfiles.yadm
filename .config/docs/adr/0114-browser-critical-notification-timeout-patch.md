# ADR-0114: Carry the browser critical-notification timeout as a bugfix patch, instead of waiting for the PR or filtering in Chromium

Status: Accepted
Date: 2026-11-11

## Context

Chromium sends a web app's notifications with `urgency=critical` and `expireTimeout=0` when the page asks for interaction; Gemini does.
Omarchy's notification plugin gives every critical card a lifetime of 0, so these cards stay until dismissed by hand and come back after a shell restart.
The sender's urgency cannot be changed from the browser side, and the shell has no setting for it.
Upstream has [issue #16641](https://github.com/omacom/omarchy/issues/16641) and [PR #16689](https://github.com/omacom/omarchy/pull/16689), still open on 2026-11-11, which gives a critical card from a browser the normal lifetime.

## Decision

`yadm/bootstrap.d/omarchy/bugfix/browser-critical-timeout.sh` applies the PR's `Service.qml` and `Store.js` hunks to `/usr/share/omarchy/shell/plugins/notifications/` through the ADR-0057 lifecycle.
The PR's docs and test hunks are not carried.
The step is deleted by hand once the PR merges.

## Consequences

A package update restores the unpatched files until the next bootstrap, and the shell needs `omarchy restart shell` to load the patch.
A critical card from a browser can now expire unseen; that is the PR's intent.
Two things stay open: a card is not dismissed when its window is focused (in `docs/BACKLOG.md`), and a click on a card focuses the window only through the existing fallbacks.
