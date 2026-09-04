---
name: grow-project-docs
description: Creating or growing a `README`, `docs/SPEC.md`, `docs/ROADMAP.md`, `docs/BACKLOG.md`, `docs/STATE.md` or `.scratch/` in one of this user's own repositories — which file holds what, and the overflow (or, for `docs/STATE.md`, work left mid-flight) that earns it. Use when starting such a project, when something in one has outgrown the file holding it, or when work on it is being left mid-flight across a session. Not for a repository whose conventions belong to someone else.
---

# Grow project docs

Records grow by overflow.
A concern earns its own file when it can no longer be stated where it lives — sometimes a section graduating out of the README, sometimes the whole README failing to contain something.

Nothing here is a schema to adopt.
These are names for common overflows, so they stay consistent across this user's projects.
A repository whose conventions belong to someone else is out of scope — there, `project-docs` finds what is already kept, and no file is created.

## Where things sit

The root holds entry points only.
Everything that overflowed goes under `docs/`, so location alone answers whether a thing overflowed.

| What is held | Where it goes | Earned when |
| --- | --- | --- |
| What this project is, and how someone uses it | `README.md` | someone reads it to use the project without changing it |
| What you would get wrong here | the repository's `CLAUDE.md` | something has surprised someone, and not before |
| What the system must do | `docs/SPEC.md` | the README cannot hold the behaviour |
| The order things happen in | `docs/ROADMAP.md` | the README's roadmap or TODO section outgrew it |
| Open work nobody is on | `docs/BACKLOG.md` | the README's TODO section outgrew it |
| Current state of work left unfinished across a session | `docs/STATE.md` | work on one concern is deliberately left mid-flight at a session boundary |
| Why it is built this way | `docs/adr/` | the `adr` skill decides — an event, never overflow |
| A procedure a person also runs by hand | a doc in `docs/`, with the skill that fires on it pointing there | a person will run it too, not only an agent |
| Throwaway material | `.scratch/` | the first temporary file is about to be written into the repository proper |
| How the project is operated | a `justfile`, the one entry here that executes instead of being read | there is a command worth a name |

## Earned, not adopted

Adopt no row until the condition beside it is met.
Until then the repository and its history are the record, and adding the file costs more than it holds.
A file that is absent has not been earned yet; that is the only thing its absence means.
An empty one is worse than absent: it advertises a record that does not exist.

Two rows are worth reading twice, because the instinct is to create them on day one.

`README.md` is earned by a reader, not by the project existing.
Where use and change are the same audience — a dotfiles tree, a private script — one file serves both and there is no README to write.

The repository's `CLAUDE.md` is earned by a surprise.
One restating what `package.json` or the CI workflow already says costs every turn of every agent, and teaches the model to discount the lines sitting beside it.

Neither carries an index line pointing at the other.

[`references/files.md`](references/files.md) carries what each file holds, its boundary against its neighbours, and a worked example.
Read it when you are about to create one.

## Creating one is two things at once

Creating a file and naming it in the project's `CLAUDE.md` are one step, never two.
One line per file: where it sits, what kind of thing it holds, and who writes it.

That line is what a later session actually reads.
A repository's `CLAUDE.md` loads every turn for every agent working in it, so `project-docs` resolves it at step one of its ladder, before anything has been opened.
The file's own first lines carry no such explanation — a second copy there goes stale, and the reader who has already opened the file no longer needs routing.

Formats stay out of it too.
A file explains its own layout by having one, and a description of that layout is wrong the first time the layout changes.

Done when every file created has met the condition beside it, each carries its line in the project's `CLAUDE.md`, and the rows that were not earned are left unwritten.
