# ADR-0041: Narrow STATE.md to a committed-versus-unfinished axis and strip behaviour out of its CLAUDE.md line

Status: Accepted
Date: 2026-09-09

## Context

ADR-0039 restored `docs/STATE.md` on a *current-versus-open* axis and flagged its own reopening bar: "If `docs/STATE.md` rots or gets abandoned in `maniac` or elsewhere despite the edit-or-drop rule, that is the finding that reopens this again."

A session in `maniac` hit exactly that.
Its `docs/STATE.md` grew to 186 lines across ten sections, holding seven ADRs' worth of already-finished work — a changelog, not a current-state file.
The proximate cause was `maniac`'s own `CLAUDE.md`, which carried: "Update it after related work lands, editing or dropping a section once it's no longer new instead of appending another one."
That line loads every turn; `grow-project-docs`'s boundary loads only when the skill fires, so the paraphrase won for the life of seven ADRs.
Nothing in the harness compares a project's record-file line against the skill that governs it, so the drift was never caught.

Underneath that sat a gap in the axis itself.
The case that broke the file was an ADR accepted but not yet implemented — not "left mid-flight" (nothing had started) and not "open and unclaimed" either, since the decision was already made and committed to.
It fit neither `docs/STATE.md`'s nor `docs/BACKLOG.md`'s stated boundary, so the project's own `CLAUDE.md` improvised a rule to cover it, and the improvised rule is what produced the changelog.
The user's own correction, given mid-session in that project, named the sharper axis: "an adr that need[s] implementation is a good example, it cannot be backlogged, also if we were to write a handoff to another session it could be in the state."
Committed-versus-not-committed partitions cleanly where current-versus-open did not.

A second, independent contributor: `grow-project-docs/references/files.md` opens the `STATE.md` entry with "What changed and what was verified," and only afterward qualifies it as "for a concern actively being implemented across more than one session."
The qualifier carries the whole boundary and arrives last, which reads as licence for changelog content until the second clause is reached.

## Decision

`docs/STATE.md` and `docs/BACKLOG.md` split on committed-versus-not-committed, not current-versus-open.

- `docs/BACKLOG.md`: work nobody has committed to — a bug found, tech debt, an unapproved idea.
- `docs/STATE.md`: work already committed to and not yet finished — an accepted ADR awaiting implementation, a change left mid-flight, the handoff a fresh session needs to resume.

`grow-project-docs/references/files.md` leads its `STATE.md` entry with that boundary sentence; "what changed and what was verified" moves after it, as detail about the unfinished work rather than the opening frame.
`project-docs`'s matching bullet gets the same two named cases so the kind is recognisable without opening the second skill.

The duplication is the defect R-one-slot already names: the same fact — how `docs/STATE.md` is kept current — had two owners, and the copy that loads every turn drifted from the copy that loads only on invocation.
R-one-slot's fix is to delete the second copy, not to keep it in sync.
`grow-project-docs/references/files.md`'s own template already asked for identity only — "where it sits, what it holds, who writes it" — and did not forbid more.
It now does: a project's `CLAUDE.md` line for a record file names identity and nothing else, and never restates the file's edit-or-append rule, its boundary against a neighbouring file, or any other behaviour `grow-project-docs` already states once.
`project-docs` step 1 gets the matching instruction: a record-file line found doing more than naming identity is a defect in the project's `CLAUDE.md`, to be trimmed back to identity, not a convention to defer to.

## Consequences

This narrows ADR-0039 on the boundary axis and the `CLAUDE.md`-contradiction gap only.
ADR-0039's other decisions — edit-or-drop rather than append, tracked in git, `leader` needing no change — stand.

Evidence is one incident: `maniac`'s `docs/STATE.md` reaching 186 lines before the contradiction was noticed and corrected.
The committed-versus-not-committed axis has not yet been run in a second project; if it too proves unusable at the moment an accepted-but-unimplemented decision shows up, that is the finding that reopens this again.

Enforcement stays prose-only.
Nothing checks that a project's record-file line stays to identity automatically — mechanizing that check (an `audit-harness` diff, or a length/keyword heuristic) was suggested and left to the backlog rather than built now, since one incident does not yet justify the mechanism.

