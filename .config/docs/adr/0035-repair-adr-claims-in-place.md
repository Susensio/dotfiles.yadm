# ADR-0035: Repair ADR claims in place instead of superseding to correct them

Status: Accepted
Date: 2026-08-26

## Context

Tracing where a commit-ownership rule belonged surfaced three defects in the record set, none of which was a wrong decision.

ADR-0022's routing line named `ENVIRONMENT_ARCHITECTURE.md` as the destination for "what the setup is now", a brief that document never held -- it explains environment-variable flow and nothing wider.
ADR-0032 recorded content as having moved to `leader`, and `leader.md` never received it; the claim was written as completed fact and was never true.
ADR-0026 read `Accepted` while ADR-0030 had already reversed its placement rule, which ADR-0030 states exactly and ADR-0026 had no way to advertise.

Each was a claim about the world or a missing pointer, and each steered a reader wrong.
The rule at the time forbade editing an accepted record's Context, Decision or Consequences, so the only sanctioned repair was a superseding record -- a whole new decision written to correct a fact.
The skill also contradicted itself: one line held that an accepted ADR's path references "rot and cannot be repaired", another that fixing a rotted pointer "changes no decision and is always allowed".

Three alternatives were weighed and discarded.

One decision per ADR would make supersession always total, since partial reversal only arose because ADR-0026 bundled four rules and ADR-0030 reversed one.
Rejected: it multiplies the record count, which is the cost this format absorbs least well, and the bundling is already written and cannot be retro-split.

A partial-supersession status would let ADR-0026 advertise its own reversal.
Rejected: a second status vocabulary maintained by hand, answering what is really a discoverability problem.

A path-existence check was run across all 34 records before being rejected on its own output.
It flagged 8, dominated by records correctly naming things that no longer existed because removing them was the decision -- ADR-0034's deleted `hooks/task-interface.py`, ADR-0023's superseded orchestrator.
It caught neither defect that prompted it: ADR-0022 cited a path that exists and mis-described it, ADR-0032 cited no path at all.
The check inverts on the "explains an absence" class the format most wants written.

## Decision

Immutability covers the decision and the reasoning that reached it.
Everything else is repairable in place -- a rotted pointer, a broken link, a typo, or a claim about the world that was false or has since become so.
A repair that changes what a line meant carries a dated note under a `## Corrections` heading saying what it said before, because a repair that leaves no trace is its own half-truth.
Supersession is reserved for a decision actually changing, which is what stops the set growing in order to correct itself.

Claims about the world are written in the past tense, anchored to the moment, where they cannot rot.
A present-tense standing fact belongs in the live file that governs it, cited by name, with the record saying what was decided about it -- the pattern ADR-0034 already used for the hook-reach facts.

An `Accepted` record binds the decision it records, and current behaviour is read from the live file the decision was operationalized into.
Reading a record as current policy is what made ADR-0026 mislead, while `harness-design` carried ADR-0030's rule correctly the whole time.

`adr.py list` derives back-references from the `ADR-NNNN` references already present in the prose, printing the later records that name an earlier one without replacing it.
Nothing is kept in step by hand, and the forward reference already exists in whichever record did the touching.

## Consequences

The record set stops growing to correct itself, and a reader of an older record can see that later ones touched it.

A repaired record is no longer a verbatim artifact of its moment.
The `## Corrections` note is the only thing between a repair and a quiet rewrite, and nothing enforces it.
"Changes no decision" is a judgement, and a motivated reader can talk themselves into repairing a decision -- this trades a format that was reliably stale for one that is reliably trusted only if the judgement holds.

A back-reference says only that a later record named this one.
Narrowing, reversal and plain citation are indistinguishable without opening it, which is why the derived column points rather than summarises.

Nothing detects a rotted claim.
Prevention is the tense test, which is convention, and the path check that would have been the detector was measured and rejected above.

ADR-0011 and ADR-0014 name paths that no longer resolve, found by that measurement.
Both are now repairable and neither has been repaired.
