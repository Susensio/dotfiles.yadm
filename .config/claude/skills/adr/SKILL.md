---
name: adr
description: Use at the start of weighing a choice between real alternatives (library, structural boundary, accepted constraint) to check binding ADRs, and at its end to record the decision in docs/adr/.
---

# Architecture Decision Record Protocol

## Before deciding
Run `${CLAUDE_SKILL_DIR}/scripts/adr.py list`: one line per ADR with number, status, and title.
`-> <N>` marks the superseding record; `<- <N>,<M>` are later ADRs naming this one (narrowing, partial reversal or citation; read them to tell).
An `Accepted` ADR on the same ground binds: follow it or supersede it deliberately, never silently re-decide.
`Superseded` is history; the live file the decision became (skill, rule, `CLAUDE.md`) is current policy.
Open a full ADR only when its title looks relevant.

## When to write one

A decision earns a record when its reason lives nowhere else: not in the diff, the config, or the tool's docs.
Reason with a line to sit beside goes there as a comment, anchored where the reasoning would be re-derived, not where the setting is typed.
An ADR is for reason with no single line to mark:
- it spans files or describes a shape (two or more anchors);
- it explains an absence, a thing deliberately not done;
- it binds future changes whose subject is not written yet.

A rule that keeps evolving belongs in the live rules file, not a fixed record.
Swapping a tool for an equivalent, or adopting a documented reversible setting, is not a decision.
Offer an ADR rather than assuming one.

## How to write one
1. `${CLAUDE_SKILL_DIR}/scripts/adr.py new "<title>" --slug "<short-slug>"` prints the new path.
   It finds `docs/adr/` by walking up; `--dir <path>` names it outright, `--init` creates it.
   The title becomes the H1 and is the whole index: name the discarded alternative in it ("Link mise tools into XDG directories instead of PATH shims").
   `--slug` is 3-6 words naming the core decision.
2. Fill **Context** (forces, stated neutrally), **Decision**, **Consequences** (trade-offs, not just upside).
   Write the world in past tense, anchored to the moment; a present-tense standing fact belongs in the live file, cited by name.
3. Cite skills and docs by name, never path.
4. Never edit an accepted ADR's decision or reasoning once committed; a draft is free to revise until the commit that lands it.
   Repair anything changing no decision (rotted pointer, typo, false claim about the world); where a repair changes a line's meaning, add a dated `## Corrections` note saying what it said before.
   To change the decision: `${CLAUDE_SKILL_DIR}/scripts/adr.py new "<title>" --slug "<short-slug>" --supersedes <N>`, which flips the old status.

There is no index file; `list` derives it.
