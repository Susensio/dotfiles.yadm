# ADR-0063: Strip the caller's herdr identity from test-harness TUIs instead of letting a nested agent claim the pane's state

Status: Accepted
Date: 2026-09-28

## Context

Panes intermittently showed `working` (yellow) while the agent inside was visibly waiting on input — an `ask_user_question` questionnaire, or pi-permission-system's "Permission Required" dialog — and once a pane went stale it never recovered for the life of that process.
It looked like the unmanaged `herdr:blocked` bridge (ADR-0060) failing, since that bridge is what turns an open questionnaire into herdr's `blocked` state, but a sibling pane with a questionnaire open at the same moment did report `blocked` correctly.

The cause was herdr's own reporting contract.
A hook-reporting pane takes its state solely from `pane.report_agent` (`screen_detection_skip_reason: full_lifecycle_hook_authority`), so herdr never re-derives it from the screen, and it applies a per-source sequence gate: a report whose `seq` is at or below the last accepted one is accepted by the API and silently ignored by the pane state (`socket-api.mdx`, "Agent state reporting").
herdr's pi integration numbers its reports from `Date.now() * 1000` at module load plus one per report, which makes its sequence a wall-clock marker rather than a per-process identity.
Any other process that inherits the pane's `HERDR_ENV=1`, `HERDR_PANE_ID`, and `HERDR_SOCKET_PATH` passes the integration's `enabled()` gate and reports for that pane; starting later, its base sequence is always larger, so from its first report on, every report from the pane's real agent is discarded.

`tui-test spawn` produced exactly that: it starts a throwaway tmux server from the calling shell, so a `pi` under test inherited the calling pane's identity and the nested `pi`'s integration claimed the pane.
The `name` tab showed the result — a permission dialog open on screen for 17 minutes with herdr reporting `working`, a live nested `pi` holding that pane's `HERDR_PANE_ID` (spawned by the very command the parent was asking permission for), and `state_change_seq` frozen while healthy panes advanced.
An isolated session reproduced it: a fresh `pi` reported its questionnaire as `blocked`; a nested `pi` then froze the pane (the real agent's transitions stopped applying, and the pane's session reference was overwritten with the child's); the same nesting with `HERDR_*` stripped left the pane reporting normally.

No recovery path existed in place, which is what made the symptom sticky: `pane.clear_agent_authority` and `pane.release_agent` did not reset the sequence watermark, and `/reload` re-registered the extensions (pi printed "Reloaded keybindings, extensions, …") without re-basing the counter — the integration's module-scope sequence survived it.
Only restarting the pi process re-based it.

Alternatives weighed: hardening the `herdr:blocked` bridge, which fails because the discarded report belongs to the managed integration and the bridge has no influence over it; having the bridge report with a dominating sequence, which would take the pane's state over permanently since no API resets the watermark; fixing herdr's integration to verify that the reporting process is the pane's agent, or its gate to sequence per reporter rather than per source — upstream, and unavailable now; and leaving spawn sites alone on the theory that agents rarely spawn agents in their own pane, which the day's usage had already falsified.

## Decision

`tui-test` unsets every `HERDR_*` variable before it starts its throwaway tmux server, so no harness-spawned TUI can claim the pane: the integrations' gates fail, and so does the `herdr` CLI's own "am I inside a pane" check.

The rule it encodes is not tui-test's own — a spawned TUI is not the pane's agent, so no spawn site may hand the pane identity through — and it is recorded as a gotcha in the `tui-testing` skill so hand-rolled spawns follow it.

## Consequences

Panes poisoned before the guard still need their pi restarted; nothing in the API or in pi's reload clears the watermark.

Harness TUIs are blind to herdr by construction: they can neither inspect nor drive the session, so testing a herdr integration means giving it a pane of its own, in a named session, rather than inheriting one.
That matches why the wrapper already hid its own tmux.

The guard closes the sanctioned path, not the class.
herdr's pi integration checks no ownership, and its sequence gate has no recovery path and no diagnostic, so a hand-rolled `pi` inside a pane — or a nested `claude` or `codex` through its hooks — still freezes the pane the same way.
That upstream gap (an ownership check, per-reporter sequencing, or a diagnostic when a report is ignored) is tracked in `docs/BACKLOG.md`.
