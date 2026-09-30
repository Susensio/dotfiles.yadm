# ADR-0073: Keep herdr scratchpad as a bare tmux persistence layer instead of sharing native scratchpad config

Status: Superseded by [ADR-0077](0077-nested-herdr-scratchpad.md)
Date: 2026-09-29
Supersedes: [ADR-0059](0059-herdr-scratchpad-workspace-id-sessions.md)

## Context

The Herdr popup needed a durable shell per workspace, not a second tmux interface inside Herdr.
ADR-0059 shared the native tmux scratchpad config through a socket-name guard, which also left tmux's default keys live and required a special `S` override.
A Herdr scratch tab would avoid the nested key surface but give up the overlay; abduco would give up screen restoration.

## Decision

Keep one tmux server with workspace-ID sessions and exact-match targets, but give it a standalone shim on `herdr_scratchpad`: no status, no prefix or root bindings except `` Alt+` `` to detach the popup client.
Keep fish, mouse, escape-time and history settings in the shim.
Retain the launch-context refusal and the deliberate absence of workspace cleanup from ADR-0059.
The theme-set hook's existing full-config marker check is what keeps it from reloading the bare Herdr server.

## Consequences

The popup remains an overlay with a persistent shell, without tmux's key grammar or its keyboard copy mode.
Mouse events stay enabled for applications, but tmux's default mouse bindings are removed too; terminal selection may require a modifier to bypass tmux.
The standalone shim no longer depends on the native scratchpad's socket suffix, hook, or `S` binding.
An already-running `herdr_scratchpad` server retains the old config until restarted; stopping it discards its persisted shells so the next popup starts the new shim.
The shim has no explicit palette or visual styles; the terminal supplies the shell's colors, while the theme hook does not reload the Herdr server.
As before, switching Herdr workspaces with an open popup can leave its tmux client attached invisibly, and closing a workspace does not clean its session.

