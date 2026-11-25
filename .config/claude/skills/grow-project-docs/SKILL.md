---
name: grow-project-docs
description: Use when starting one of the user's own repos, when README, SPEC, ROADMAP, BACKLOG, STATE, a plan, a report or .scratch/ is needed or outgrown, or when work is left mid-flight. Not for repos with others' conventions.
---

# Grow project docs

Records grow by overflow.
A concern earns its own file when it can no longer be stated where it lives.
These are names for common overflows, kept consistent across this user's projects, not a schema to adopt.
A repository whose conventions belong to someone else is out of scope -- there, `project-docs` finds what is kept, and no file is created.

## Where things sit

The root holds entry points only; everything that overflowed goes under `docs/`.
Below, `AGENTS.md` means the project's context file, or the `CLAUDE.md` it keeps instead.
Never keep both: Claude ignores an `AGENTS.md` beside a `CLAUDE.md`.

| What is held | Where it goes | Earned when |
| --- | --- | --- |
| What this project is, and how someone uses it | `README.md` | someone reads it to use the project without changing it |
| What you would get wrong here | the repository's `AGENTS.md` | something has surprised someone, and not before |
| What the system must do | `docs/SPEC.md` | the README cannot hold the behaviour |
| The order things happen in | `docs/ROADMAP.md` | the README's roadmap or TODO section outgrew it |
| Open work nobody is on | `docs/BACKLOG.md` | the README's TODO section outgrew it |
| Current state of work left unfinished across a session | `docs/STATE.md` | work on one concern is deliberately left mid-flight at a session boundary |
| A proposal too long for a backlog line | `docs/plans/<name>.md` | the reasoning and order of work no longer fit the entry that started it |
| One review's or investigation's findings | `docs/reports/<name>.md` | findings outnumber what a reply can carry |
| Why it is built this way | `docs/adr/` | the `adr` skill decides — an event, never overflow |
| A procedure a person also runs by hand | a doc in `docs/`, with the skill that fires on it pointing there | a person will run it too, not only an agent |
| Throwaway material | `.scratch/` | the first temporary file is about to be written into the repository proper |
| How the project is operated | a `justfile`, the one entry here that executes instead of being read | there is a command worth a name |

## Earned, not adopted

Adopt no row until its condition is met.
Until then the repository and its history are the record.
An absent file has not been earned yet; an empty one is worse, advertising a record that does not exist.

Two rows are the ones to create on day one by instinct:

- `README.md` is earned by a reader, not by the project existing.
  Where use and change are the same audience -- a dotfiles tree, a private script -- one file serves both.
- The repository's `AGENTS.md` is earned by a surprise.
  One restating what `package.json` or CI already says costs every agent turn and teaches the model to discount the lines beside it.

Neither carries an index line pointing at the other.

[`references/files.md`](references/files.md) carries what each file holds, its boundary against its neighbours, and a worked example.
Read it when you are about to create one.

## Creating one is two things at once

Creating a file and naming it in the project's `AGENTS.md` are one step.
One line per file: where it sits, what kind of thing it holds, and who writes it.
That line is what a later session reads: `AGENTS.md` loads every turn, so `project-docs` resolves it at step one of its ladder.
The file's own first lines carry no such explanation, and no description of its layout -- a file explains its layout by having one.

Done when every file created has met its condition, each carries its line in `AGENTS.md`, and the unearned rows are left unwritten.
