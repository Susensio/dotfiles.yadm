---
name: project-state
user-invocable: false
description: Where a project's own record lives — its plan, its open work, its working notes, its scratch space — and which of those files the project has earned yet. Use when something needs writing down and the destination is not obvious, when `docs/README.md` is missing or names nothing, and before creating any PLAN, BACKLOG or STATE file.
---

# Project state

A project's record is written for a person to read, so it is a doc in `docs/`, not a file under `.claude/`.

Adopt none of it on day one.
Each file below names the condition that earns it.
Until that condition is met the repository and its history are the record, and adding the file costs more than it holds.

## The pointer

`docs/README.md` names where the project's requirements, plan and working notes live, and the command that verifies the work.
It is the one file read to find the rest, so it holds pointers and nothing else.

Missing, or naming nothing: work from the repository as it is and say so once.
Never guess a layout from what happens to be on disk.

Do not create it to hold a single line.
A project with one plan file and no check command is better served by naming that file when asked.

## The record

Each entry: what it holds, who writes it, and the boundary that stops it absorbing its neighbours.
Names are defaults — where `docs/README.md` names a different location, that one wins.

### docs/PLAN.md — what is intended

Milestones, and the anti-goals that say what this project will deliberately not do.
The user writes it; agents read it and do not edit it unasked.

*Earned when* the work spans more sessions than one plan can be held in.
*Boundary:* an architectural shift goes here, never into the backlog.
The anti-goals are the part that cannot be recovered from reading the code, so they are the part worth writing first.

### docs/BACKLOG.md — what is open but not being worked

Discovered bugs, tech debt, and explorations nobody has approved.
Shared: agents append what they find outside their current scope rather than following it.

*Earned when* something is found that will not be fixed in this session and has no single line to mark.
*Boundary:* not what is being coded right now.

A defect that has one wrong line is marked on that line instead, if the project marks defects in place.
The backlog holds what no single line can carry.
Never copy those markers in to make the backlog a full index: the copy kept by hand is the one that goes stale.
Name the search that lists them in the backlog's header instead.
Generating that index is possible and rarely worth it — weigh the machinery against how many markers the repo actually carries.

Where the project already keeps a backlog, its format wins.
Otherwise: one entry per line — priority, area, one sentence — and an entry needing a repro, a link, or what was already tried carries an indented block under it.

```
## Bugs
- High | auth | Token refresh fails after 24h offline.
  Only when the refresh lands during a clock skew of more than 60s.
  Tried: widening the leeway window, no change.

## Tech debt
- Refactor | parser.ts | 1000 lines, split into strategies.

## Explorations
- Explore | state | Replace the store with a context provider?
```

`rg '^- '` still yields the flat list.
An entry that outgrows the block is a decision, not a backlog item.

### STATE.md — what is being worked right now

The current objective, the live blocker, and the dead ends already tried.
Agents own it.
Add it to whatever ignore file the project already uses before writing it, and wipe it when the work it describes is committed.

*Earned when* a session has actually been lost and the reconstruction cost was felt.
Not before.

*Boundary:* the harness keeps its own task list, held per session rather than per repository (observed, v2.1.223).
That list holds the steps.
`STATE.md` holds only what would be expensive to reconstruct after the session ends — the blocker, and what was tried and failed.
A `STATE.md` that reads as a copy of the task list is deleted, not reconciled: it will drift, and the copy that drifts is the one written by hand.

### .scratch/ — working material

Throwaway scripts, captured output, a dump being read once.
Add it to whatever ignore file the project already uses before writing into it, and wipe it when the work that produced it is committed.

*Earned when* the first temporary file is about to be written into the repository proper.
It exists so that never happens.

*Boundary:* nothing here is ever the source of truth.
Material that survives the task belongs in one of the files above, or is deleted with the directory.

## Routing what does not go in a file above

**A procedure with two readers** — a deployment, a release, a test suite a person also runs by hand — is a doc in `docs/`, and the skill that fires on it points there.

**A choice between real alternatives**, once settled or reversed, goes to the `adr` skill, which decides whether it is worth recording at all.
