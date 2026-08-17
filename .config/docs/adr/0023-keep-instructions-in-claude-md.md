# ADR-0023: Keep agent instructions in CLAUDE.md instead of extracting an orchestrator

Status: Superseded by [ADR-0026](0026-harness-content-by-tier.md)
Date: 2026-08-15

## Context

`CLAUDE.md` files are inherited by subagents, not just the main session. Adding
a delegation and model-selection policy to `~/.claude/CLAUDE.md` therefore ships
it to every subagent spawned, including ones that will never delegate.

This problem was already hit once, in `antigravity-harness`, and solved by
extraction: the delegation rules moved out of `CLAUDE.md` into an
`agents/orchestrator.md` role, set as the main agent via `settings.json`. The
instinct on seeing it again was to repeat that fix — "I had this same problem
with antigravity-harness and that was the reason for extracting an orchestrating
main subagent".

Extraction was correct there for a reason that does not carry over. That harness
ran five roles, and its policy contained statements that invert by reader:
"never write application code yourself" is right for the orchestrator and broken
inside the developer. Instructions whose truth depends on who is reading them
cannot share a file. The policy adopted here is four bullets, none of which
invert — the only reader-dependent phrasings were incidental ("the main
model", "my context") rather than structural.

## Decision

Keep the delegation and model-selection policy in `CLAUDE.md` and scope each
rule to its trigger rather than to its audience, so that inherited instructions
are inert for a reader they do not apply to instead of wrong.

In practice: the block opens with `Before spawning a subagent`, so an agent that
never delegates never applies it, and reader-relative terms are written as roles
("whoever is deciding", "the caller's context") rather than as a fixed vantage
point. Extract a separate agent role only once a rule is true for the main
session and false inside a subagent.

## Consequences

No orchestrator indirection to maintain: the main session stays the default
agent, and reading `CLAUDE.md` is enough to know the policy. The rules also
happen to be correct for a subagent that does delegate further, which the
extracted-role version could not express.

Trigger-scoping is a discipline, not a mechanism. Nothing detects a rule that
silently became reader-dependent, and the failure is quiet — a subagent
obeying an instruction meant for the session above it. The trip-wire is
verbal: reaching for "you" to mean specifically the main session means the
rule now belongs in an extracted role, and the split deferred here has to be
done then.

Cost of deferring: if that day comes, the policy has to be separated out of two
`CLAUDE.md` files rather than having been written into a role from the start.
Judged cheaper than carrying an orchestrator layer for four bullets that do not
need one — the ADR-0020 trade, one level down.
