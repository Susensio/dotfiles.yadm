---
name: adr
description: Records an architecturally significant decision as a numbered ADR in docs/adr/, and checks what is already binding before a new one is made. Use right after a choice between real alternatives is settled or reversed — a library, a structural boundary, a constraint accepted for a non-obvious reason — and before settling one, so a prior decision is followed or superseded deliberately rather than silently re-litigated.
---

# Architecture Decision Record Protocol

## Before deciding
Run `rg -N '^Status: (.+)$' -r '$1' docs/adr/0*.md | sort` — one line per ADR in
number order, filename and status. An `Accepted` ADR covering the same ground is
binding: follow it, or supersede it deliberately (below). Never silently
re-decide. `Superseded` is history, not current policy. Open a full ADR only when
its filename looks relevant.

## When to write one
Record a decision here when it changes how the system is built and would be expensive to rediscover later: choice of a library/framework/datastore, a structural boundary (service split, API shape), a reversal of a previous decision, or a constraint adopted for a non-obvious reason. Don't record routine implementation choices, naming, or anything reversible without cost — that's noise, not a decision worth an ADR.

The test is whether real alternatives were weighed. Adopting a documented, reversible setting because the tool's own docs say to — even one that reads as structural — is not a decision, it's a transcription: there is no discarded alternative for future-you to rediscover. Offer an ADR in that case rather than assuming one is warranted.

## How to write one
1. Run `${CLAUDE_SKILL_DIR}/new.py "<title>" --slug "<short-slug>"` — prints the created file's path. It finds `docs/adr/` by walking up from wherever it is invoked, and creates it if the repo has none. `<title>` can be a full sentence and becomes the H1; `--slug` is 3-6 words naming the core decision and becomes the filename — pick it deliberately rather than letting the title get truncated into it.
2. Fill in the three sections:
   - **Context:** the situation and forces at play, stated neutrally (why this needed a decision at all).
   - **Decision:** what was decided, stated as a single clear sentence.
   - **Consequences:** what becomes easier or harder as a result — trade-offs, not just upside.
3. Never edit an accepted ADR's Context/Decision/Consequences after the fact. If the decision changes, write a new ADR that supersedes it:
   `${CLAUDE_SKILL_DIR}/new.py "<title>" --slug "<short-slug>" --supersedes <N>`
   This writes `Supersedes: [ADR-<N>](<file>)` into the new file and flips ADR-`<N>`'s status to `Superseded by [ADR-<M>](<file>)` — the old record stays, it just stops being current.

Titles are in the filenames, status is in each file. There is no index file to
fall out of date. `rg -l '^Status: Superseded' docs/adr/0*.md` lists just the
dead ones.
