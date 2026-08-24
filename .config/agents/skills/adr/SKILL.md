---
name: adr
description: Records an architecturally significant decision as a numbered ADR in docs/adr/, and checks which earlier decisions are still binding. Use when a choice between real alternatives is settled, reversed or superseded — a library, a structural boundary, a constraint accepted for a non-obvious reason — and before settling one, to find what already decided it.
---

# Architecture Decision Record Protocol

## Before deciding
Run `${CLAUDE_SKILL_DIR}/adr.py list` — one line per ADR in number order: number, status, title.
A superseded record shows `-> <N>`, the number that replaced it, in place of its status.
An `Accepted` ADR covering the same ground is binding: follow it, or supersede it deliberately (below).
Never silently re-decide.
`Superseded` is history, not current policy.
Open a full ADR only when its title looks relevant.

## When to write one

A decision earns a record when the reason for it lives nowhere else — not in the diff, not in the config it produced, not in the tool's own docs.

Ask where that reason would otherwise sit.
Reason with a line to sit beside goes there as a comment, and the comment is the better record: whoever next edits the line finds it, without knowing `docs/adr/` exists.
Two lines and an upstream link beside the setting beat a file nobody opens.
A comment also travels with the file it annotates, where an accepted ADR's path references rot and cannot be repaired.

Anchor to where the reasoning would be re-derived, not to where the setting is typed.
A fix often lands somewhere other than the place that was investigated, and it is the place investigated that gets guessed wrong a second time.

An ADR is for reason with no single line to mark:
- it spans files, or describes a shape rather than a line — one anchor is a comment, two or more is a shape;
- it explains an absence, the thing deliberately not done that no line can carry;
- it binds future changes, so its subject is not written yet — a standing policy or a repo-wide convention has no line to sit beside because that line does not exist.

A rule that keeps being edited as it evolves belongs in the live rules file it governs, not in a record fixed at a moment.

Swapping one tool for an equivalent is not a decision when the diff already shows why.
Adopting a documented, reversible setting because the tool's own docs say to — even one that reads as structural — is transcription, not decision: there is no discarded alternative for future-you to rediscover.
Offer an ADR rather than assuming one is warranted.

## How to write one
1. Run `${CLAUDE_SKILL_DIR}/adr.py new "<title>" --slug "<short-slug>"` — prints the created file's path.
   It finds `docs/adr/` by walking up from wherever it is invoked.
   If there is none it stops and says where it looked, rather than starting a second set somewhere nobody reads.
   `--dir <path>` names the directory outright when the search would find the wrong one; `--init` creates it, for a project with no records yet.
   `<title>` can be a full sentence and becomes the H1; `--slug` is 3-6 words naming the core decision and becomes the filename — pick it deliberately rather than letting the title get truncated into it.
   The title is the whole index, since it is what `list` prints: name the discarded alternative in it where there was one.
   "Link mise tools into XDG directories instead of PATH shims" answers "did I already weigh PATH shims?" without the file being opened; the slug alone does not.
2. Fill in the three sections:
   - **Context:** the situation and forces at play, stated neutrally (why this needed a decision at all).
   - **Decision:** what was decided.
   - **Consequences:** what becomes easier or harder as a result — trade-offs, not just upside.
3. Never edit an accepted ADR's Context/Decision/Consequences after the fact.
   If the decision changes, write a new ADR that supersedes it:
   `${CLAUDE_SKILL_DIR}/adr.py new "<title>" --slug "<short-slug>" --supersedes <N>`
   This writes `Supersedes: [ADR-<N>](<file>)` into the new file and flips ADR-`<N>`'s status to `Superseded by [ADR-<M>](<file>)` — the old record stays, it just stops being current.

Title and status live in each record and `list` reads them from there.
There is no index file to fall out of date.
