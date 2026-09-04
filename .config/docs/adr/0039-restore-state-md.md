# ADR-0039: Restore docs/STATE.md to the schema, keyed on work spanning sessions

Status: Accepted
Date: 2026-09-04

## Context

ADR-0038 withdrew `STATE.md` from `grow-project-docs`'s schema, on ADR-0037's own terms: ADR-0037 had left the row unvalidated and named the reopening bar itself — "the first real project settles it: whether any of the three gets reached for, or worked around."
ADR-0038 cited no practitioner account of the file surviving adoption, an `earned when` framed as an event nobody recognises in the moment ("a session actually lost"), and two findings against: a claimed on-disk multi-session task list doing the same job, and an instruction file edited mid-session not being reliably re-read.
ADR-0037 also flagged a contradiction: `STATE.md` was specified gitignored while also being mandated, which pulls apart if its purpose is to change.

`maniac`, a user project outside this repository, committed `docs/HANDOFF.md` on 2026-09-02 (commit `3b41a64`), holding "the current implementation state and verification evidence for the next maintainer," declared in its own `CLAUDE.md`.
One day after ADR-0038 withdrew the row, this is the reopening ADR-0037 asked for: a real project reached for the shape, under its own invented name, without having read either prior record.
At the moment of writing this ADR, that project also carries an uncommitted rename of the file to `docs/STATE.md` and an uncommitted addition of an edit-or-drop rule to its `CLAUDE.md` line — in-progress work, not yet a second data point, and not counted as evidence here.

Checked at decision time: no on-disk multi-session task list existed in this Claude Code build.
`TaskOutput`/`TaskStop` track background shells, agents and remote sessions, not implementation state — a different kind of content — so the alternative ADR-0038 deferred to does not cover this need.

The mid-session re-read risk ADR-0038 named applies to a file wired as always-loaded instructions, the way `CLAUDE.md` is.
`leader` already reads the project's record — in whatever form a project keeps it — at session start, after compaction, and when a subagent returns, and keeps it current as the same move.
A `docs/STATE.md` read the same way carries no risk the record does not already carry today, whatever file currently holds it.

## Decision

`docs/STATE.md` returns to `grow-project-docs`'s table and file reference, and to `project-docs`'s list of kinds — the taxonomy and the filenames are split across those two, and both need the entry or the agent that autoloads only the first never learns the kind exists.

*Earned when* work on one concern is deliberately left unfinished across a session boundary.
That is decidable at the moment work stops, unlike "a session was lost," which is only ever recognised after the fact.

It holds the current, verified state of in-flight implementation work for the next session to pick up — what changed and what was verified.
*Boundary:* against `docs/BACKLOG.md`, current versus open-and-unclaimed; against an ADR, transient versus settled.
This is wider than the "blockers and dead ends only" content ADR-0038 recorded as the prior convergence; the widening matches what a project actually needs to hand off implementation work, not just its snags.

It is edited, or a section dropped, as work supersedes it — never appended to, and deleted along with its `CLAUDE.md` line once the work it tracks lands.
That is what stops it becoming either a log or a stale advertisement for a record no longer true.

It is tracked in git like the project's other records, not gitignored — dropping the gitignore requirement ADR-0037 flagged as pulling against a mandated file, rather than dropping the file.

No change to `leader`: its existing rule to read the project's record — in whatever form a project keeps it — at session start, after compaction, and on subagent return, and to keep it current, already covers `docs/STATE.md` once a project has one.

## Consequences

This narrows ADR-0038 on the `STATE.md` row only.
Its decision on overflow, the `PLAN.md`-to-`ROADMAP.md` rename, the backlog format, the `project-docs`/`grow-project-docs` split, and the ownership hook all stand unchanged.

`grow-project-docs` gains a `docs/STATE.md` row and section, and its trigger widens to cover work left mid-flight, not only a file outgrowing what holds it.
`project-docs` gains the matching kind, so `leader` — which autoloads `project-docs`, not `grow-project-docs` — knows the kind exists without needing the second skill to fire.

Practitioner evidence is one committed data point: `maniac`'s `docs/HANDOFF.md`, reached for under an invented name one day after this row was withdrawn — the reopening ADR-0037 asked for, though smaller than a settled convention.
If `docs/STATE.md` rots or gets abandoned in `maniac` or elsewhere despite the edit-or-drop rule, that is the finding that reopens this again.

Enforcement stays thin, matching every other row in the table: nothing checks that a project keeps `docs/STATE.md` current, edits rather than appends, or deletes it once the work it tracks lands — that rests on `leader`'s prose and the anti-rot rule being read.
