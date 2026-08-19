---
name: adr
description: Records an architecturally significant decision as a numbered ADR in docs/adr/, and checks which earlier decisions are still binding. Use when a choice between real alternatives is settled, reversed or superseded — a library, a structural boundary, a constraint accepted for a non-obvious reason — and before settling one, to find what already decided it.
---

# Architecture Decision Record Protocol

## Before deciding
Run `rg -N '^Status: (.+)$' -r '$1' docs/adr/0*.md | sort` — one line per ADR in number order, filename and status.
An `Accepted` ADR covering the same ground is binding: follow it, or supersede it deliberately (below).
Never silently re-decide.
`Superseded` is history, not current policy.
Open a full ADR only when its filename looks relevant.

## When to write one

Record a decision that changes how the system is built and would be expensive to rediscover later: a library/framework/datastore choice, a structural boundary (service split, API shape), a reversal of a previous decision, or a constraint adopted for a non-obvious reason.
Not routine implementation choices, naming, or anything reversible without cost.

The test is whether real alternatives were weighed.
Adopting a documented, reversible setting because the tool's own docs say to — even one that reads as structural — is transcription, not decision: there is no discarded alternative for future-you to rediscover.
Offer an ADR there rather than assuming one is warranted.

## How to write one
1. Run `${CLAUDE_SKILL_DIR}/new.py "<title>" --slug "<short-slug>"` — prints the created file's path.
   It finds `docs/adr/` by walking up from wherever it is invoked.
   If there is none it stops and says where it looked, rather than starting a second set somewhere nobody reads.
   `--dir <path>` names the directory outright when the search would find the wrong one; `--init` creates it, for a project with no records yet.
   `<title>` can be a full sentence and becomes the H1; `--slug` is 3-6 words naming the core decision and becomes the filename — pick it deliberately rather than letting the title get truncated into it.
2. Fill in the three sections:
   - **Context:** the situation and forces at play, stated neutrally (why this needed a decision at all).
   - **Decision:** what was decided, stated as a single clear sentence.
   - **Consequences:** what becomes easier or harder as a result — trade-offs, not just upside.
3. Never edit an accepted ADR's Context/Decision/Consequences after the fact.
   If the decision changes, write a new ADR that supersedes it:
   `${CLAUDE_SKILL_DIR}/new.py "<title>" --slug "<short-slug>" --supersedes <N>`
   This writes `Supersedes: [ADR-<N>](<file>)` into the new file and flips ADR-`<N>`'s status to `Superseded by [ADR-<M>](<file>)` — the old record stays, it just stops being current.

Titles are in the filenames, status is in each file.
There is no index file to fall out of date.
`rg -l '^Status: Superseded' docs/adr/0*.md` lists just the dead ones.
