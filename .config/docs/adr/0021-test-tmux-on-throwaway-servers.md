# ADR-0021: Test tmux only on isolated throwaway servers

Status: Superseded by [ADR-0025](0025-split-tmux-skills-knowledge-execution.md)
Date: 2026-08-07

## Context

An agent working on `tmux.conf` or `conf.d/*.conf` is normally launched *from inside* the user's own tmux session.
A bare `tmux` invocation in a test targets `$TMUX` — the user's live server — so one stray `kill-server`, `set -g`, or `source-file` during a test can wreck a running workspace.
Separately, `capture-pane` only dumps a pane's content buffer; popups, menus, and other client-side overlays are composited at render time and never appear in it, so naive checks report success while proving nothing about what rendered.

## Decision

Every tmux test runs against its own throwaway server: explicit `-L <socket>` on every invocation, `unset TMUX` before shelling out, `-f /dev/null` plus an explicit `source-file` for the config under test, a distinctive socket name, and cleanup on every exit path including failures.
`scripts/tmux-test` encodes this protocol so the cleanup paths aren't reinvented per script.
For visual checks (popups, menus, cursor state), nest a second server as the eyeball and `capture-pane` *its* pane, per `references/nested_session_visual_testing.md`.
Test execution is delegated to the `tmux-tester` subagent, keeping pane captures and retry loops out of the calling agent's context.

## Consequences

Tests can't touch live work by construction.
Visual behavior becomes verifiable at all, not just content-buffer state.

Cost: any visual check needs two servers and their cleanup, not one.
Delegating to `tmux-tester` costs an agent round-trip instead of an inline command, and that agent starts with no context — it must be briefed fully each time.
The isolation rule itself can't be enforced mechanically, so it has to be restated to every new agent.

