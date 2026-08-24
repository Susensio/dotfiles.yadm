---
name: project-docs
user-invocable: false
description: Where a project's own information goes — what is intended, what is open, what is being worked now, throwaway material, a settled decision — and whether the project has earned a file for it yet. Use when something needs writing down, before creating any of these files, and when picking up a project's existing record.
---

# Project docs

A project's record is written for a person to read, so it is a doc in `docs/`, not a file under `.claude/`.

## Where it goes

| What you are holding | Where it goes |
| --- | --- |
| What is intended, and what this project deliberately will not do | `docs/PLAN.md` |
| Open work nobody is on — a found bug, tech debt, an unapproved idea | `docs/BACKLOG.md` |
| What is being worked right now — the objective, the live blocker, the dead ends already tried | `STATE.md` |
| Throwaway material — a script, captured output, a dump read once | `.scratch/` |
| A choice between real alternatives, once settled or reversed | the `adr` skill, which decides whether it is worth recording |
| A procedure a person also runs by hand — a deployment, a release | a doc in `docs/`, and the skill that fires on it points there |
| A defect with one wrong line to sit beside | that line, where the project marks defects in place |

**Never agent memory**, while anything above fits.
It is unreviewable, invisible to everyone else working in the repository, and does not reach a subagent — so a fact kept there is missing from whoever does the work next.
One place, never both.

## Earned, not adopted

Adopt none of it on day one.
Until a file's condition is met the repository and its history are the record, and adding the file costs more than it holds.
A file that is absent has not been earned yet; that is the only thing its absence means.
An empty one is worse than absent: it advertises a record that does not exist.

Once a file exists it speaks for itself, because it opens by naming what it holds and what it excludes.
One line does that; the format it uses is not the file's to explain.
So nothing indexes these files and no pointer file lists them — read what is in `docs/`, and read a file before writing to it.

Names are defaults.
Where a project already keeps one of these somewhere else, that location wins, and its `CLAUDE.md` is where it says so.

## Creating one

`references/creating.md` carries what earns each file, the boundary line to write into it, and a worked example.
Read it when you are about to create one, not before.
This skill has nothing to add once the file is there.
