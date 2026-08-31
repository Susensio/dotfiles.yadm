---
name: project-record
user-invocable: false
description: Where a project keeps its own information — what is intended, what is open, what is being worked, a settled decision, a defect — and how to find that place in a project you did not set up. Use when picking up a project, when something found needs writing down, and before adding any file to hold it.
---

# Project record

A project's record is written for a person to read, so it is a doc in the repository, not a file under `.claude/`.
Where it sits is the project's call, not yours; finding where is the work.

## Find it before adding to it

0. **Whether your change lands here directly.**
   Where it goes through someone else's review instead, what you found travels in your report or through what that project uses to propose a change, under `Someone else's repository` below.
1. **What the project declares about itself** — its `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING`, `README`, taking the nearest one above the files you touched, which outranks the root's where they disagree.
   A location named there wins over anything you would otherwise reach for; a location you settle on that nothing named earns a line there.
2. **What it visibly keeps** — a `docs/` tree, a `TODO`, a changelog, an issue tracker it points at.
   Match that location and that format, however little it resembles what you would have chosen.
   Where more than one qualifies, follow what the project has most recently done with a finding of that kind; where that is still unclear, ask rather than pick.
   List the root directly: a file holding live working state is ignored, so `rg` and `fd` skip it.
3. **No home for this kind yet**, and setting this project's conventions is yours to do.
   The `bootstrap-project-docs` skill carries where each kind goes, and what earns a file for it.

Read a file before writing to it, and where it declares what it holds and excludes, that line governs.

## Name the kind, then find its home

- **What this project is**, and how someone uses it.
- **What is open** and nobody is on — a found bug, tech debt, an unapproved idea.
- **What is being worked right now** — the objective, the live blocker, the dead ends already tried.
- **A procedure a person also runs by hand** — a deployment, a release.

Those four go wherever the ladder lands.
The rest have an answer that holds in any project:

- **A defect with one wrong line to sit beside** is marked on that line, where the project marks defects in place and its tree is yours to edit.
- **A choice between real alternatives**, once settled or reversed, goes to the `adr` skill, which decides whether it is worth recording at all.
- **Throwaway material** — a script, captured output, a dump read once — goes somewhere the project already ignores, and is gone when the work commits.
- **How the project is operated** is whatever it already declares: a `justfile`, `package.json` scripts, the CI workflow.

## Someone else's repository

Any edit to their tree changes someone else's project — a marker on one wrong line as much as a new file.
Where the conventions belong to someone else, what you found travels in your report first.
Anything that would post in public — an issue, a pull request, a review comment — is the user's to send, not yours: the `report-issue` skill drafts one for them to submit, and never files it itself.

## Never agent memory

While any kind above fits, the record is a file in the repository.
Agent memory is unreviewable, invisible to everyone else working there, and does not reach a subagent — so a fact kept there is missing from whoever does the work next.
One place, never both.
