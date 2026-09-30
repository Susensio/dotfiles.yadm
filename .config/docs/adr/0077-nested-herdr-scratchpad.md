# ADR-0077: Use nested Herdr named sessions for popup scratchpads instead of tmux persistence

Status: Accepted
Date: 2026-09-30
Supersedes: [ADR-0073](0073-bare-herdr-scratchpad.md)

## Context

The bare tmux server in ADR-0073 kept scratch shells alive between Herdr popup opens, but removed tmux's copy mode and left the popup unable to scroll its history.
Restoring tmux bindings would reintroduce a second key grammar; a scratch tab would lose the overlay, and an ad-hoc popup shell would lose persistence.
Herdr named sessions have separate sockets and persistent panes, and a client can run inside a popup with nested launch enabled.

## Decision

Run one named Herdr session per originating workspace ID from the popup, using a config with a hidden collapsed sidebar, a tab bar hidden for a single tab, copy mode on the outer prefix, and no workspace, tab or split creation keys.
Herdr has no config include, so the scratchpad uses the `terminal` theme rather than copying the outer config's built-in theme.
Detach the inner client on `` Alt+` `` to close the popup without stopping the session.
Herdr replaces a closed last workspace rather than exiting, so the scratch shell is a wrapper that stops its own session when fish exits, mirroring tmux's `detach-on-destroy`.
Clear the outer socket and caller identifiers before launch so inner CLI commands and panes use their own session, but start each workspace's scratch in that workspace's own directory.
Herdr launches popup commands from the workspace root directory, and the inner config sets `terminal.new_cwd = "current"` so the nested session uses that process directory instead of defaulting to `$HOME`.
Keep the launch-context refusal and no workspace cleanup.

## Consequences

Scratchpads scroll with the mouse wheel and Herdr copy mode (`F12`, `v`), start in the outer workspace's own directory, and share the outer Herdr key grammar without depending on tmux.
Each workspace now owns a Herdr server rather than a session on one tmux server; closing a workspace still leaves an orphan until manually stopped or deleted.
Herdr restores a named session's saved workspace cwd, so a scratchpad created before the workspace-directory rule keeps its old directory until its session is deleted, not just stopped.
Scratchpad chrome follows the host terminal's palette, which Omarchy switches with its theme, so it can differ slightly from the outer Herdr's pinned built-in theme.
The inner client briefly paints Herdr's machine picker on every attach: its pre-snapshot frame ignores the collapsed sidebar settings, which no config reaches.
That flash stays until Herdr fixes it upstream (herdrdev/herdr#4790).
The old tmux scratch sessions remain on their existing socket until stopped manually and are not migrated into Herdr panes.
Switching outer workspaces while a popup is open can still leave the inner client attached invisibly.
