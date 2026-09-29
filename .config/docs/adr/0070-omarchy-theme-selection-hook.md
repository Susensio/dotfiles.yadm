# ADR-0070: Record Omarchy theme selection through a theme-set hook instead of tracking generated state

Status: Accepted
Date: 2026-09-29

## Context

Omarchy stored the selected theme in ignored current-theme state, while yadm tracked the user's theme overlays and templates.
A fresh clone could re-render an existing selection but could not select the same theme on a new machine.
Tracking Omarchy's state file directly would make generated state part of the repo; a fixed theme declaration alone would fail to follow changes made through Omarchy's menu.

## Decision

Record the selected theme slug in a tracked user-config file through Omarchy's `theme-set` hook.
At bootstrap, select that theme through Omarchy's normal theme setter when the current selection is missing or different, then continue the existing stale-template check.
Do not track the generated theme directory or Omarchy's own selection state file.

## Consequences

An ordinary theme switch marks the tracked selection file as changed; the user must commit it to carry the choice to another machine.
If the selected theme is unavailable on a machine, bootstrap fails rather than silently substituting another theme; install that theme or change the declaration before retrying.
A first run with the tracked choice applies the full theme, including backgrounds and application updates when a desktop session exists; a headless run defers live updates until login.
A stale-template-only bootstrap remains headless and does not retint the running shell or tmux.
Theme switches during bootstrap still run Omarchy's normal tmux updater and the existing user hook; the separate live-tmux checks remain open.
