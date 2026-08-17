---
name: adr
description: Records an architecturally significant decision as a numbered ADR in docs/adr/. Judgment on when something is worth recording lives here; the mechanics (numbering, slugifying, supersede bookkeeping) live in new.py.
---

# Architecture Decision Record Protocol

## When to write one
Record a decision here when it changes how the system is built and would be expensive to rediscover later: choice of a library/framework/datastore, a structural boundary (service split, API shape), a reversal of a previous decision, or a constraint adopted for a non-obvious reason. Don't record routine implementation choices, naming, or anything reversible without cost — that's noise, not a decision worth an ADR.

## How to write one
1. Run `python3 .claude/skills/adr/new.py "<short title>"` from the repo root — prints the created file's path.
2. Fill in the three sections:
   - **Context:** the situation and forces at play, stated neutrally (why this needed a decision at all).
   - **Decision:** what was decided, stated as a single clear sentence.
   - **Consequences:** what becomes easier or harder as a result — trade-offs, not just upside.
3. Never edit an accepted ADR's Context/Decision/Consequences after the fact. If the decision changes, write a new ADR that supersedes it:
   `python3 .claude/skills/adr/new.py "<short title>" --supersedes <N>`
   This writes `Supersedes: ADR-<N>` into the new file and flips ADR-`<N>`'s status to `Superseded by ADR-<M>` — the old record stays, it just stops being current.

## How to list them
Titles are in the filenames, status is in each file. There is no index file to
fall out of date:

```sh
rg -N '^Status: (.+)$' -r '$1' docs/adr/0*.md | sort   # all, with status
rg -l '^Status: Superseded' docs/adr/0*.md             # just the dead ones
```
