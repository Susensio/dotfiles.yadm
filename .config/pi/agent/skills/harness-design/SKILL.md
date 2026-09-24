---
name: harness-design
description: Designs and trims agent harnesses, system instructions, agent definitions, and skills. Use when adding, moving, reviewing, or rewriting agent-facing configuration; applies placement, routing, brevity, and anti-bloat tests.
---

# Harness design

A harness earns its size by changing observed behaviour. Preserve useful source material outside discovery rather than keeping every lesson active.

## Place content

- **Global `AGENTS.md`:** behaviour needed in most sessions or before a routing decision.
- **Agent:** a stable execution bundle of model, permissions, isolation, independence, and output contract.
- **Skill:** reusable knowledge or procedure needed under an observable condition.
- **Extension:** enforcement, interaction, or visualization that prose cannot provide reliably.
- **Project guidance:** facts and conventions that would be false in another repository.
- **Human documentation:** rationale and operational detail an agent need not load to act correctly.

Intentional duplication is allowed only across context boundaries or for different readers. Keep one authoritative copy for each reader.

## Admit additions

Add a component only when all are true:

1. It addresses a repeated observed need.
2. Native behaviour, an existing component, or project guidance does not cover it.
3. Its behavioural benefit exceeds its context, routing, and maintenance cost.

A new agent changes model, permissions, isolation, or independence. A new skill carries substantial conditional knowledge. A new extension mechanizes or visualizes something prose cannot. A new global instruction matters widely or must arrive before choosing a skill or tool.

Remove a component when its trigger cannot be stated, it repeats another source, or representative sessions behave the same without it.

## Write for agents

Lead with the action or governing rule. Prefer positive instructions; pair an unavoidable prohibition with the intended alternative.

Use prose for one governing idea or rationale that resolves edge cases. Use bullets for independent constraints. Use numbered steps only when order matters. Do not turn every qualification into an equal-priority bullet.

Descriptions route discovery. In one short sentence, state the capability and observable triggers; add an exclusion only when confusion is likely. Put workflow, rationale, and examples in the body.

Keep examples that distinguish correct from plausible-wrong behaviour. Cut generic encouragement, environment facts that are cheap to inspect, repeated conclusions, hedges, and instructions the model already follows.

## Verify

Test effective behaviour with representative tasks rather than asking an agent to describe its configuration. Verify permissions by attempting the relevant tool, skill discovery with realistic prompts, and enforcement at the boundary that claims to hold it. Record runtime-specific facts only when they affect current design.
