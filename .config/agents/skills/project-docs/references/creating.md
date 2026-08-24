# Creating a record file

Each entry below: what earns the file, what it holds, and the boundary that stops it absorbing its neighbours.

Creating one means writing that boundary into the file's own first lines — one line naming what it holds and what it excludes.
Not the format: a file that explains its own field layout is carrying the skill's job, and it goes stale the first time the layout changes.

## docs/PLAN.md — what is intended

Milestones, and the anti-goals that say what this project will deliberately not do.
The user writes it; agents read it and do not edit it unasked.

*Earned when* the work spans more sessions than one plan can be held in.

*Boundary:* an architectural shift goes here, never into the backlog.

The anti-goals are the part that cannot be recovered from reading the code, so they are the part worth writing first.

```markdown
# Plan

What this project is for, and what it will not do.

## Milestones

## Anti-goals
- No plugin system. Every extension so far has been one function.
```

## docs/BACKLOG.md — what is open but not being worked

Discovered bugs, tech debt, and explorations nobody has approved.
The main agent writes it, from its own work and from whatever a subagent reports as outside its scope.
Subagents read it and do not append — an entry landing in a scoped diff breaks the single concern that diff was supposed to be, and reading it is what stops one repeating a dead end recorded here.

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
The main agent owns it, and nothing else writes it: a subagent has no next turn to leave notes for, and several running at once would clobber the file carrying the caller's continuity.
What a subagent needs from it travels in the brief instead, which is why `delegation` makes "what was already tried" a named slot.
Add it to whatever ignore file the project already uses before writing it, and wipe it when the work it describes is committed.

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
