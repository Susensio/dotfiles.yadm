# What each record file holds

Each entry below: what earns the file, what it holds, and the boundary that stops it absorbing its neighbours.

A pointer to each file lives in the project's `AGENTS.md`, not in the file's own first lines.
One line there per file, naming identity only — where it sits, what kind of thing it holds, who writes it — never the boundary or behaviour below, which stays here as the one copy.
A file that explains itself is carrying that line's job in a copy nobody routes by, and it goes stale the first time the boundary moves.
An `AGENTS.md` line caught restating a boundary or an edit/append rule is a defect in the project: trim it back to identity, do not sync it (ADR-0041).

## README.md — what this project is

What it does, and what someone types to use it, present tense, as though it already works.
Written before the code: a README you cannot keep short is telling you the project is not clear yet.

*Earned when* there is a reader who uses the project without changing it.
Where use and change are the same audience, one file serves both and this is not earned — a dotfiles tree has no README and needs no excuse for it.

*Boundary:* what a reader needs in order to use it.
Why it is built this way is an ADR, what it must do is `docs/SPEC.md`, and milestones that outgrow this file are `docs/ROADMAP.md`.

## AGENTS.md — what you would get wrong here

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
Subagents read it to find what is open before starting something.

*Earned when* the README's TODO section outgrew it.

*Boundary:* not committed to, and not what one wrong line can carry.
Each entry names something someone could start, or what would unblock it.
A decision not to do something is a decision, so it goes to the `adr` skill; git history keeps anything dropped.
Ground an accepted ADR already covers is settled rather than open.
Once a decision is made — an ADR accepted, a change started — it has left this file for `docs/STATE.md`, even with zero lines of implementation (ADR-0041).
A defect with a line to sit beside is marked on that line, where the project marks defects in place.
Never copy those markers in to make it a full index: the copy kept by hand is the one that goes stale.

Where the project already keeps a backlog, its format wins, though a section of settled decisions is drift rather than format.
Otherwise one entry per line, with an indented block under any entry needing a repro, a link, or what was already tried:

```markdown
# Backlog

- tmux | tmux-notify: floating-pane notification tray and toasts for agents and bells.
  See tmux/PROPOSAL-tmux-notify.md.
- auth | Token refresh fails after 24h offline.
  Only when the refresh lands during clock skew over 60s.
  Tried: widening the leeway window, no change.
```

An area prefix where it helps `rg`, and left off where it does not.
No priority, no sections, no kind: every field an entry must carry is a reason to not write the finding down, and the finding not written is the cost this file exists to avoid.
The kind is already in the sentence — "fails after 24h" is a bug, "1000 lines, split into strategies" is debt.
Sections come back if the flat list stops being readable, which is the same overflow rule one level down.

The indented block is the part that pays, and it has a ceiling: an entry that outgrows it is a decision, and belongs in an ADR instead.

## docs/STATE.md — work committed to and not yet finished

Work already decided or already started that is not done: an accepted ADR awaiting implementation, a change left mid-flight, the handoff a fresh session needs to resume it.
What changed and what was verified belongs here too, as detail about that unfinished work, never as the file's own opening frame.
The main agent writes it and keeps it current.

*Earned when* work moves from proposed to committed and is not yet finished — deciding something, or leaving it mid-flight across a session boundary, are both committing.
This is checkable the moment the commitment happens, not an event recognised only after something has already gone wrong.

*Boundary:* committed, not merely proposed.
`docs/BACKLOG.md` holds work nobody has committed to yet; the moment an ADR is accepted it has left the backlog and belongs here instead, whether or not implementation has started (ADR-0041).
Why a choice was made stays in the ADR — this file tracks only that it is not yet done.
Edit the file, or drop a section once it is no longer current — never append.
An append-only file is a log, and a log is not what a fresh session needs: it needs the current truth, not its history.
Delete it, and its `AGENTS.md` line, once the work it tracks lands — an empty or stale one advertises a record that is no longer true.

## .scratch/ — working material

Throwaway scripts, captured output, a dump being read once.
A spec written to brief one piece of work and then discarded lives here too.
Add it to whatever ignore file the project already uses before writing into it, and wipe it when the work that produced it is committed.

*Earned when* the first temporary file is about to be written into the repository proper.
It exists so that never happens.

*Boundary:* nothing here is ever the source of truth.
Material that survives the task belongs in one of the files above, or is deleted with the directory.
