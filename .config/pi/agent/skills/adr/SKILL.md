---
name: adr
description: Checks binding decisions and records numbered architecture decision records. Use before and after choosing between durable architectural alternatives.
---

# Architecture decision records

Use the helper at [scripts/adr.py](scripts/adr.py), resolving the path relative to this skill directory.

## Before deciding

Run `scripts/adr.py list` against the project's `docs/adr/` directory and open records whose titles cover the decision.
An accepted ADR on the same ground is binding: follow it or supersede it deliberately.
Never silently re-decide it.
A superseded ADR is history, not current policy.
Consult the live code, configuration, or guidance for the operational rule; the ADR explains why it was chosen.

## Decide whether to record

An ADR is warranted for a durable choice between real alternatives when its reason has no better local home and is likely to be revisited.
Typical cases include a structural boundary, an intentionally absent mechanism, or a non-obvious constraint that binds future changes.

Prefer a nearby comment when the reason belongs to one specific line or setting.
Do not create an ADR for a reversible transcription of upstream documentation, a tool swap explained by the diff, or a rule that belongs in an editable live policy.
Offer an ADR rather than assuming every architectural-looking change needs one.

## Write the record

Create a record with:

```text
scripts/adr.py new "<descriptive title>" --slug "<short-slug>"
```

Pass `--init` only when deliberately starting `docs/adr/`, or `--dir <path>` when upward discovery would choose the wrong project.
Choose a title that identifies the alternative rejected or constraint accepted; titles are the index.

Use three sections:

- **Context:** the situation, alternatives, and forces that required a decision.
- **Decision:** the choice made.
- **Consequences:** what becomes easier or harder, including accepted limitations.

Describe the decision-time world in past tense so the record does not pretend to be live documentation.
Refer to stable component, skill, or document names rather than paths likely to move.

## Preserve history

Revise a draft freely until the commit that accepts it.
After acceptance, do not rewrite its decision or original reasoning.
Repair typos, broken references, and false non-decision claims; add a dated `Corrections` note if the repair changes a line's meaning.

When the decision changes, create a successor:

```text
scripts/adr.py new "<new decision>" --slug "<short-slug>" --supersedes <N>
```

Keep the old record as superseded history.
Do not maintain a separate hand-written index; derive listings from the records.
