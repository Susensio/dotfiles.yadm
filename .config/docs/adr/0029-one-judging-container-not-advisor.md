# ADR-0029: Widen auditor into one judging container instead of enabling the advisor tool

Status: Accepted
Date: 2026-08-19

## Context

Claude Code ships a server-side `advisor` tool (beta `advisor-tool-2026-03-01`), enabled by `/advisor` or an `advisorModel` setting and gated by a pairing rule requiring the advisor to rank at least as high as the base model.
When enabled it appends a ~500-token instruction block to the system prompt and pushes an `advisor` schema into the request; the model then calls it on its own judgment, forwarding the entire conversation to a stronger reviewer on every call, with no per-call approval.
Its own instructions ask for a call before committing to an approach and again before declaring work done.

The harness already had review machinery reached deliberately rather than automatically.
`auditor` judges against a standard the caller names, cold and read-only; `tester` verifies against something running under an isolation protocol it loads from a skill.
`auditor` was pinned to `sonnet`, described as inspecting work already produced, and returned findings in an audit shape — serviceable for a harness audit or a diff, useless for judging an approach with nothing yet on disk.

Three options were weighed: enable the advisor tool, add a separate `advisor` agent beside `auditor`, or widen `auditor` to cover the case.

The forces ran mostly one way.
The advisor tool reads a transcript; a cold agent reads the repository, runs its own commands, and can spawn `tester` for a verdict against a live process — evidence the advisor tool structurally cannot reach.
Advisor cost scales with conversation length on every call, a cold handoff with the size of what is judged.
A reviewer that never saw the reasoning cannot be anchored by the framing that produced the error.

Against that, a cold reviewer sees only what it is pointed at and what it can discover for itself, so reasoning that never reached disk is invisible to it — the one thing the advisor tool does better.

A separate `advisor` agent was ruled out by R1 rather than by preference: it would have shared `auditor`'s container properties exactly — read-only scoping, cold start, a model pin — differing only in prompt text, which is the definition of content that belongs in a skill.

## Decision

Keep one judging container.
`auditor` widens from inspecting produced work to judging anything it did not produce — a harness, a config tree, a diff, a proposed approach — against a standard the caller names, taking its output shape from the caller's skill and falling back to a defect branch or an approach branch when none is named.
It pins `opus` and its description triggers proactively before work is declared done.

The server-side advisor tool stays disabled, and no sibling agent is added.
Domains bind through the skill the caller names — `audit-harness` today, a code-review skill when one is written, and no skill at all for advice judged against a standard the caller states directly.

This is ADR-0025's move applied to a second container: that record generalized `tmux-tester` into a domain-agnostic `tester`, and the same argument decides `auditor`.

## Consequences

Three uses share one container, and a fourth needs a skill rather than an agent.
Review reaches live state, because `auditor` may spawn `tester`; no configuration of the advisor tool would have bought that.
Cost scales with the artifact under judgement instead of with how long the session has run, and a review that never saw the reasoning cannot inherit its blind spot.

The reviewer never sees that reasoning either.
Anything wrong that left no trace on disk is invisible to it, and the prompt naming the target is written by the same session being checked.
Requiring `auditor` to establish its own scope rather than accept the caller's framing narrows this to omission — it cannot be closed, only bounded.

Proactive triggering rests on the model choosing to fire it, so this is a probability where a server-side tool call would have been closer to a certainty.
The same soft failure ADR-0026 accepted for the delegation skill, one level up: a review that does not happen rather than a wrong action.

The `opus` pin raises the cost of every audit, and R3 records that a pin is a default the caller's `model` argument overrides — the cost is a tendency, not a guarantee, in either direction.

The trigger lives in the description at the user tier, so it fires in every project rather than this one.
That is deliberate, and it means a project that does not want a proactive auditor has to say so.

Cost: `auditor`'s remit is now broad enough to be reached for where something narrower would do, and its description has to carry that breadth in text loaded into every session.
The advisor tool remains available if the trade changes — nothing here forecloses enabling it later for work whose reasoning matters more than its artifacts.
