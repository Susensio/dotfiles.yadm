---
name: project-docs
user-invocable: false
description: Use when picking up a project, when something found needs writing down, and before adding a file to hold it. Says where a project keeps its info (what, plan, open work, decisions, defects).
---

# Project docs

A project's record is for a person to read, so it lives in the repository, not under `.claude/`.
Finding where it already lives is the work.

## Find the home before writing

**0. Whose repository?** Run `git remote -v`.
An `upstream` remote means someone else's even where `origin` is your fork; no remote means yours; otherwise yours only if you own `origin`.
Without `Bash`, treat it as someone else's.
Someone else's: create nothing, not even a `BUG:` marker; findings travel in your report.
Anything that would post publicly is the user's to send: `report-issue` drafts, never files.
Say nothing when it is yours; report only when it is not.

**1. What does it say about itself?** `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING`, `README`.
The nearest one above the files you touched wins.
Below, `AGENTS.md` means the project's context file or the `CLAUDE.md` it keeps instead; never keep both, since Claude ignores an `AGENTS.md` beside `CLAUDE.md`.

**2. What does it visibly keep?** A `docs/` tree, `TODO.md`, `CHANGELOG.md`, a linked tracker.
Match it.
Where two fit, follow the one most recently used for a finding like yours, else ask.
List the root directly: live-state files are often gitignored and `rg` and `fd` skip them.

**3. Nothing holds this kind yet** and the repository is yours: `grow-project-docs` has this user's filenames and what earns each.

Read a file before writing to it.
A line in the project's `AGENTS.md` doing more than naming a file's identity is a defect: trim it back (ADR-0041).

## What kind of thing is it?

- What the project is and how to use it: `README`.
- What it must do: a spec.
- Order of work: `ROADMAP`; the user writes it, you do not edit it unasked.
- Open work nobody committed to (bug, debt, idea): `BACKLOG`, `TODO` or tracker.
  A subagent reports it and the main agent writes it.
- A proposal or one review's findings, too long for a backlog line: `docs/plans/` or `docs/reports/`, deleted when its last item lands.
- A procedure a person also runs: a doc, with the skill pointing there.
- Committed, unfinished work and handoff: `STATE.md`, edited or dropped as work moves, not appended.

Three skip the ladder.
A settled choice between real alternatives, including a decision not to do something, goes to the `adr` skill.
A standing fact goes beside its code as a comment, or in a path-scoped rule if it spans a path.
Throwaway material goes wherever the project already ignores.

Never agent memory: it is unreviewable and does not reach subagents.
