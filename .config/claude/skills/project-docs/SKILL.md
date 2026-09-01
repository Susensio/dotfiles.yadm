---
name: project-docs
user-invocable: false
description: Where a project keeps its own information — what it is, what is planned, what is open, a settled decision, a defect — and how to find that place in a project you did not set up. Use when picking up a project, when something found needs writing down, and before adding any file to hold it.
---

# Project docs

A project's record is written for a person to read, so it lives in the repository, not under `.claude/`.
Finding where it already lives is the work — you rarely get to choose.

## Find the home before writing

**0. Whose repository is this?** Run `git remote -v`.
An `upstream` remote means someone else's even where `origin` is your own fork, no remote at all means yours, and otherwise it is yours only if you own `origin`.
Without `Bash` you cannot answer this: treat the repository as someone else's and report rather than write, which is the answer that is never harmful to be wrong about.
Someone else's and you create nothing — not a file, not a `BUG:` marker on one wrong line — because what you found travels in your report instead.
Anything that would post in public is the user's to send: `report-issue` drafts it for them and never files it.

**1. What does it say about itself?** `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING`, `README`.
Take the nearest one above the files you touched; it beats the root's where they disagree.

**2. What does it visibly keep?** A `docs/` tree, `TODO.md`, `CHANGELOG.md`, an issue tracker it links to.
Match it, even where the format is not what you would have chosen.
Two candidates: follow whichever it used most recently for a finding like yours, and ask if that is still unclear.
List the root directly — a file holding live state is often gitignored, and `rg` and `fd` skip those.

**3. Nothing holds this kind yet**, and step 0 said the repository is yours.
The `grow-project-docs` skill has this user's filenames and what earns each.

Read a file before writing to it.
Someone else's may declare its own boundary in its first lines and that governs; this user's will not, because the repository's own `CLAUDE.md` carries it — one line per file.

## What kind of thing is it?

Five go wherever the ladder lands:

- **What this project is**, and how someone uses it — a `README`.
- **What it must do** — a spec, a requirements doc.
- **The order things happen in** — a `ROADMAP`, milestones, a pinned issue. The user writes it; you read it and do not edit it unasked.
- **What is open and nobody is on** — a bug found, tech debt, an unapproved idea. A `BACKLOG`, a `TODO`, an issue tracker.
  A subagent reports it and the main agent writes it, so a finding never rides in a scoped diff.
- **A procedure a person also runs by hand** — a deploy, a release. A doc, with the skill that fires on it pointing there.

Two never touch the ladder: a settled choice between real alternatives goes to the `adr` skill, which decides whether it is worth recording at all, and throwaway material goes wherever the project already ignores, gone when the work commits.

Roadmap or backlog, when both fit: `grow-project-docs` holds that boundary.

Never agent memory: it is unreviewable, invisible to everyone else working there, and does not reach a subagent, so a fact kept there is missing from whoever works next.
