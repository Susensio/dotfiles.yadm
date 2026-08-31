---
name: bootstrap-project-docs
description: This user's documentation conventions for a project whose conventions are theirs to set — which file holds what, where it goes, and what earns it. Use when starting such a project, or when an existing one of theirs keeps no record and should.
---

# Bootstrap project docs

Creates a file once it is earned, and nothing before.
A repository whose conventions belong to someone else is out of scope — there, `project-record` finds what is already kept.

## The conventions

| What is held | Where it goes | Earned when |
| --- | --- | --- |
| What this project is, and how someone uses it | `README.md` | the project has a name — this one is day one |
| Milestones, once they outgrow the README | `docs/PLAN.md` | the README is no longer where the next step is found |
| Open work nobody is on — a found bug, tech debt, an unapproved idea | `docs/BACKLOG.md` | something found will not be fixed this session and has no single line to mark |
| What is being worked right now — the objective, the live blocker, the dead ends already tried | `STATE.md` | a session has actually been lost and the reconstruction cost was felt |
| Throwaway material — a script, captured output, a dump read once | `.scratch/` | the first temporary file is about to be written into the repository proper |
| A procedure a person also runs by hand — a deployment, a release | a doc in `docs/`, and the skill that fires on it points there | a person will run it too, not only an agent |
| How the project is operated — the command to test it, lint it, run it | a `justfile`, the one entry here that executes instead of being read | there is a command worth a name |

## Earned, not adopted

The `README.md` is day one; adopt no other row until the condition beside it is met.
Until a file's condition is met the repository and its history are the record, and adding the file costs more than it holds.
A file that is absent has not been earned yet; that is the only thing its absence means.
An empty one is worse than absent: it advertises a record that does not exist.

Once a file exists it speaks for itself, so nothing indexes it beyond the line naming it.

[`references/creating.md`](references/creating.md) carries what earns each file, the boundary line to write into it, and a worked example.
Read it when you are about to create one.

## What this leaves behind

Create only what is already earned.
On day one that is the `README.md`, written before the code, and its line in the project's `CLAUDE.md`.

Creating a file and naming it in the project's `CLAUDE.md` are one step, never two.
One line per file: where it sits, and what kind of thing it holds.
Written at creation, that line names what exists and never advertises what does not.

It is what a later session actually reads.
`CLAUDE.md` loads every turn for every agent in the repository, so `project-record` resolves it at step one of its ladder; a file's own boundary line costs a read to reach, and the table above is loaded only by whoever invoked this skill.

Formats stay out of it.
A file explains its own layout to whoever opens it, and a second copy in `CLAUDE.md` goes stale the first time that layout changes.

Done when every file created has met the condition beside it, each carries its line in the project's `CLAUDE.md`, and the rows that were not earned are left unwritten.
