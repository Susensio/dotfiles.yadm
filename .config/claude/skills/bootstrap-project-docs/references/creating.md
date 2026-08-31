# Creating a record file

Each entry below: what earns the file, what it holds, and the boundary that stops it absorbing its neighbours.

Creating one means writing that boundary into the file's own first lines — one line naming what it holds and what it excludes.
Not the format: a file that explains its own field layout is carrying the skill's job, and it goes stale the first time the layout changes.

## README.md — what this project is

What it does, and what someone types to use it, present tense, as though it already works.
Written before the code: a README you cannot keep short is telling you the project is not clear yet.

*Earned when* the project has a name — the one file earned on day one.

*Boundary:* what a reader needs in order to use it.
Why it is built this way is an ADR, a topic needing more than a paragraph is a doc in `docs/`, and milestones that outgrow this file earn `docs/PLAN.md`.

## docs/PLAN.md — the order things happen in

Milestones, once there are more of them than the README can carry.
The user writes it; agents read it and do not edit it unasked.

*Earned when* the work spans more sessions than one plan can be held in, and the README is no longer where the next step is found.

*Boundary:* an architectural shift goes here, never into the backlog.
What the project is stays in the README; this file holds only the order things happen in.

```markdown
# Plan

The order things happen in. What this project is, is in the README.

## Milestones
```

## docs/BACKLOG.md — what is open but not being worked

Discovered bugs, tech debt, and explorations nobody has approved.
The main agent writes it, from its own work and from whatever a subagent reports as outside its scope.
Subagents read it, and reading it is what stops one repeating a dead end recorded here.

*Earned when* something is found that will not be fixed in this session and has no single line to mark.

*Boundary:* not what is being coded right now.

A defect with one wrong line is marked on that line instead, where the project marks defects in place.
The backlog holds what no single line can carry.
Never copy those markers in to make it a full index: the copy kept by hand is the one that goes stale.
Name the search that lists them in the header instead.

Where the project already keeps a backlog, its format wins.
Otherwise one entry per line — priority, area, one sentence — with an indented block under an entry needing a repro, a link, or what was already tried:

```markdown
# Backlog

Open work with no single line to mark. `rg -n 'BUG:|TODO:'` lists the rest.

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
An entry that outgrows its block is a decision, not a backlog item.

## STATE.md — what is being worked right now

The current objective, the live blocker, and the dead ends already tried.
The main agent owns it, and subagents neither read nor write it.
Nothing else writes it: a subagent has no next turn to leave notes for, and several running at once would clobber the file carrying the caller's continuity.
Nothing else reads it either: the brief is the only thing that tells a subagent what to build, and one that reads the caller's continuity inherits the caller's framing and widens its own scope.
What a subagent needs from it travels in that brief, which is why `delegation` makes "what was already tried" a named slot.
Add it to whatever ignore file the project already uses before writing it, and wipe it when the work it describes is committed.
Root, not `docs/`: this is continuity, not record, and it is gone by the time anyone would go looking in `docs/` for it.
Not `.claude/` either — the harness owns that directory, and what is being worked outlives any one harness.

*Earned when* a session has actually been lost and the reconstruction cost was felt.
Not before.

*Boundary:* the harness keeps its own task list, held per session rather than per repository (observed, v2.1.223).
That list holds the steps.
`STATE.md` holds only what would be expensive to reconstruct after the session ends — the blocker, and what was tried and failed.
A `STATE.md` that reads as a copy of the task list is deleted, not reconciled: it will drift, and the copy that drifts is the one written by hand.

```markdown
# State

Live working state. Wiped when the current work commits.

## Objective

## Blocked on

## Tried and failed
```

## .scratch/ — working material

Throwaway scripts, captured output, a dump being read once.
Add it to whatever ignore file the project already uses before writing into it, and wipe it when the work that produced it is committed.

*Earned when* the first temporary file is about to be written into the repository proper.
It exists so that never happens.

*Boundary:* nothing here is ever the source of truth.
Material that survives the task belongs in one of the files above, or is deleted with the directory.
