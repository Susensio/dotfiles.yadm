---
name: project-docs
user-invocable: false
description: Whether a project has earned a PLAN, BACKLOG or STATE file or a scratch directory yet, and what shape to give one when creating it. Use before creating any of them, and when something needs writing down and the project has no file that already holds it.
---

# Project docs

A project's record is written for a person to read, so it is a doc in `docs/`, not a file under `.claude/`.

Adopt none of it on day one.
Each file below names the condition that earns it.
Until that condition is met the repository and its history are the record, and adding the file costs more than it holds.
A file that is absent has not been earned yet; that is the only thing its absence means.

Once a file exists it speaks for itself, because it opens by stating what it holds.
So nothing indexes these files and no pointer file lists them — read what is in `docs/`, and read a file before writing to it.
A name is not a convention: `docs/BACKLOG.md` states in its own first lines what stays a marker in the code instead, which beats any assumption about what a backlog usually holds.
This skill has nothing to add once the file is there.

## The record

Each entry: what earns it, what it holds, and the boundary that stops it absorbing its neighbours.
Names are defaults — where a project already keeps one of these somewhere else, that location wins, and its `CLAUDE.md` is where it says so.
Creating one means writing that boundary into the file's own first lines.

### docs/PLAN.md — what is intended

Milestones, and the anti-goals that say what this project will deliberately not do.
The user writes it; agents read it and do not edit it unasked.

*Earned when* the work spans more sessions than one plan can be held in.
*Boundary:* an architectural shift goes here, never into the backlog.
The anti-goals are the part that cannot be recovered from reading the code, so they are the part worth writing first.

### docs/BACKLOG.md — what is open but not being worked

Discovered bugs, tech debt, and explorations nobody has approved.
Shared: what is found outside the current scope is recorded here rather than followed — an agent whose brief scopes it to certain files reports it instead of appending.

*Earned when* something is found that will not be fixed in this session and has no single line to mark.
*Boundary:* not what is being coded right now.

A defect that has one wrong line is marked on that line instead, if the project marks defects in place.
The backlog holds what no single line can carry.
Never copy those markers in to make the backlog a full index: the copy kept by hand is the one that goes stale.
Name the search that lists them in the backlog's header instead.

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
