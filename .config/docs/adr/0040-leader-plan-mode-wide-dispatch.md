# ADR-0040: Plan wide or underspecified work before leader dispatches it, instead of leaving it to judgement

Status: Accepted
Date: 2026-09-07

## Context

ADR-0033 kept `leader` to three ungated things -- a quick check, a quick fix, and reconciling returns -- and dispatches everything else by footprint, per `delegation`.
That boundary says who does the work, not whether the approach was settled before subagents started on it: today it is fixed the moment `leader` picks it, with the user seeing it only once subagents return.
A wrong call on a single-subsystem, unambiguous dispatch is a cheap redo.
A wrong call on work spanning several subsystems, or too underspecified for `leader` to dispatch without the user narrowing it, surfaces only after subagent context is already spent, and costs a second fan-out to fix.

`AskUserQuestion` does not fit: it resolves a blocking choice or two, not a worked-out approach.
`EnterPlanMode` does -- explore, decide, exit for sign-off -- but `leader` never reached for it.

## Decision

`leader` plans by default for work spanning several subsystems, or too underspecified to dispatch without the user narrowing it first, through `EnterPlanMode`, before any subagent spawns.
A quick check, a quick fix, or a dispatch to one subagent with an unambiguous brief skips this -- their shape is already known, which is a separate question from the three things ADR-0033 keeps ungated for `leader` itself.
Dispatch then executes the approved plan; a plan too big for one sitting is written down via `project-docs`, not just approved -- the kind ADR-0039 added for work left mid-flight across a session covers it.

## Consequences

A wide or underspecified task gains a checkpoint the user can redirect before subagent context is spent, at the cost of one interruption per such task -- worth it because redoing one subagent's brief is cheap and redoing several is not.

This is the second decision to reach for the kind ADR-0039 introduced in `project-docs`: an approved plan too big to finish in one sitting is exactly the shape that kind was built for, so it lands there rather than needing a new kind or a new file.
Enforcement remains convention, as elsewhere in `leader`'s instructions.
