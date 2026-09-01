# What each record file holds

Each entry below: what earns the file, what it holds, and the boundary that stops it absorbing its neighbours.

The boundary lives in the project's `CLAUDE.md`, not in the file's own first lines.
One line there per file — where it sits, what it holds, who writes it.
A file that explains itself is carrying that line's job in a copy nobody routes by, and it goes stale the first time the boundary moves.

## README.md — what this project is

What it does, and what someone types to use it, present tense, as though it already works.
Written before the code: a README you cannot keep short is telling you the project is not clear yet.

*Earned when* there is a reader who uses the project without changing it.
Where use and change are the same audience, one file serves both and this is not earned — a dotfiles tree has no README and needs no excuse for it.

*Boundary:* what a reader needs in order to use it.
Why it is built this way is an ADR, what it must do is `docs/SPEC.md`, and milestones that outgrow this file are `docs/ROADMAP.md`.

## CLAUDE.md — what you would get wrong here

The repository's own, at its root — never the userspace one under `$CLAUDE_CONFIG_DIR`, which is this user's global preferences and carries no project's filenames.

The local knowledge that would otherwise be learned by breaking something: a root that is not where it looks, a command that must not be run directly, a convention no file states.
Plus one line per record file, naming where it sits, what it holds and who writes it.

*Earned when* something has surprised someone. Not on day one.

*Boundary:* corrections, not orientation.
The test is whether the line would still be true for a reader who is never going to edit anything — if yes it belongs in the README.
Anything `package.json`, a justfile or the CI workflow already declares is not a surprise and does not go here.

## docs/SPEC.md — what the system must do

The behaviour it is required to have, as distinct from how it is used.

*Earned when* the README cannot hold the behaviour without ceasing to be a README.
This one answers to no section — it is the whole document failing to contain something, which is why it is easy to miss when overflow is read as sections graduating.

*Boundary:* required behaviour, not intended sequence.
When it happens is `docs/ROADMAP.md`; why it was chosen is an ADR.
A spec written to brief one piece of work, then discarded, is `.scratch/` — not this.

## docs/ROADMAP.md — the order things happen in

Ordered groups — phases, milestones, releases — holding the large items that decompose into other work.
The user writes it; agents read it and do not edit it unasked.

*Earned when* the README's roadmap or TODO section outgrew it.

*Boundary:* an entry here contains other work.
An entry that is itself one unit of work is a backlog entry, however large it looks.
Nothing is ever *promoted* from the backlog to here: a leaf does not become a container, and a backlog item is worked and crossed off where it sits.
Correcting a misfile is not promotion, and costs a one-line move.
A roadmap item you have stopped intending goes back to the backlog rather than rotting here.

```markdown
# Roadmap

## Phase 1 — MVP

- Write backend
- Basic auth
```

## docs/BACKLOG.md — what is open but not being worked

Discovered bugs, tech debt, and explorations nobody has approved.
The main agent writes it, from its own work and from whatever a subagent reports as outside its scope.
Subagents read it, and reading it is what stops one repeating a dead end recorded here.

*Earned when* the README's TODO section outgrew it.

*Boundary:* not what is being coded right now, and not what one wrong line can carry.
A defect with a line to sit beside is marked on that line, where the project marks defects in place.
Never copy those markers in to make it a full index: the copy kept by hand is the one that goes stale.

Where the project already keeps a backlog, its format wins.
Otherwise one entry per line, with an indented block under any entry needing a repro, a link, or what was already tried:

```markdown
# Backlog

- Bell tray for headless agent-view sessions (`--bg`, no pty).
  See tmux/PROPOSAL-agent-bell-tray.md.
- auth | Token refresh fails after 24h offline.
  Only when the refresh lands during clock skew over 60s.
  Tried: widening the leeway window, no change.
```

An area prefix where it helps `rg`, and left off where it does not.
No priority, no sections, no kind: every field an entry must carry is a reason to not write the finding down, and the finding not written is the cost this file exists to avoid.
The kind is already in the sentence — "fails after 24h" is a bug, "1000 lines, split into strategies" is debt.
Sections come back if the flat list stops being readable, which is the same overflow rule one level down.

The indented block is the part that pays, and it has a ceiling: an entry that outgrows it is a decision, and belongs in an ADR instead.

## .scratch/ — working material

Throwaway scripts, captured output, a dump being read once.
A spec written to brief one piece of work and then discarded lives here too.
Add it to whatever ignore file the project already uses before writing into it, and wipe it when the work that produced it is committed.

*Earned when* the first temporary file is about to be written into the repository proper.
It exists so that never happens.

*Boundary:* nothing here is ever the source of truth.
Material that survives the task belongs in one of the files above, or is deleted with the directory.
