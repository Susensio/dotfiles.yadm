# ADR-0074: Display Pi subagents with metadata instead of competing with the managed Herdr lifecycle reporter

Status: Accepted
Date: 2026-09-29

## Context

Herdr's managed Pi integration reported idle when the parent settled, even while detached subagents continued to run.
Its only companion-extension input was `herdr:blocked`; it had no supported input for extra working activity.
A second `pane.report_agent` source could temporarily override the status, but isolated tests showed that the reporters competed, a later report could mask blocked state, and releasing the second source did not restore the first source's state.
Replacing the managed integration would require owning its session and state behavior across upstream updates.

## Decision

A separate Pi extension listened to top-level `pi-subagents` lifecycle events and reported a compact dot per running subagent through `pane.report_metadata`'s guarded `display_agent` field.
It left `pane.report_agent` and the managed integration untouched.

## Consequences

Herdr's sidebar showed subagent activity without a config change or an additional lifecycle authority.
The semantic pane status remained idle after the parent settled: waits, notifications, and workspace rollups did not treat subagent activity as working.
The indicator was limited to the loaded Pi process's observed top-level subagents; a reload during a running subagent lost its dot until another start event, and a crash could leave a dot until the metadata TTL expired.

