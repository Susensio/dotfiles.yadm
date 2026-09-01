# ADR-0030: Keep the delegation trigger in CLAUDE.md and the policy in the skill

Status: Accepted
Date: 2026-08-20

## Context

ADR-0026 moved the delegation policy out of `CLAUDE.md` into the `delegation` skill, because only skills load on demand and seven lines were shipping into every spawn.
It priced the loss as soft -- "fires on a description match rather than being unconditionally present", costing "a worse model choice, not a wrong action".

That pricing assumed nothing was arguing the other way.
Claude Code v2.1.223 argues the other way twice, and only one of the two is in the system prompt:

- The `Agent` tool's own description carries "Do not spawn agents unless the user asks -- Only use this tool when the user explicitly says to use a subagent", injected when `subscriptionType` is `pro`.
  A tool description is sent whenever the tool is available, so no system-prompt change reaches it -- including running a custom agent as the main agent via `--agent`.
- The system prompt carries "Do not call the AgentTool unless the user requested it", gated on the main model advertising the `opus_5_prompt_bundle` capability.
  Present on Opus 5, absent on Sonnet, so an `opusplan` default retires this one by itself.

A skill cannot answer the first.
`delegation` fires on a description match, and its own description says to use it "before spawning any subagent" -- which presupposes the decision to spawn was already taken.
Nothing loads it in the case that matters: the turn where delegating was never considered.
There the failure is not a worse model choice, it is no delegation at all, against an instruction that is present every turn.

A rule in `.claude/rules/` without `paths:` looks like the third option, loading at session start and reaching no subagent.
R1 already rejects it as a trap and says to write the glob or write CLAUDE.md, and there is no glob for "delegate more".

## Decision

`CLAUDE.md` carries the trigger and nothing else: that delegating is the agent's own call, and that this outranks the `Agent` tool's instruction to wait for the user.
Everything downstream -- which agent, whether the handoff pays, which model, how to write a brief that stands alone -- stays in the `delegation` skill.

This reverses ADR-0026 on placement alone.
Its tier question, its one-copy-per-skill rule and its fresh-repo rule are untouched.

## Consequences

Three lines reach every subagent again, including `developer`, `explorer` and `tester`, which declare no `Agent` tool and cannot act on them.
That is the cost ADR-0026 bought off, re-incurred deliberately at the smallest size that still fires.

The trigger is unconditional, so the Pro-tier brake is answered on every turn rather than whenever a description happens to match.
Routing stays out of `CLAUDE.md`: which agent to reach for is already in each agent's own `description`, which the roster surfaces anyway.

Both brakes are plan- and version-dependent, and neither is contractual.
The Opus one lifts on Sonnet, the Pro one on Max, and a release can move or drop either -- at which point these three lines pay rent for nothing.
R1 in the `harness-design` skill carries the exception and is where that re-check belongs, since the rules file is policy and this record is history.
