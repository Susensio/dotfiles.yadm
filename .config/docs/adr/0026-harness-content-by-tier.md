# ADR-0026: Place harness content by tier and load cost

Status: Accepted
Date: 2026-08-17
Supersedes: [ADR-0023](0023-keep-agent-instructions-in-claude-md-instead-of-ex.md)

## Context

Harness material had accumulated in three places -- this repo, a generator repo
(`antigravity-harness`), and a consuming project -- with no rule deciding what
belonged where. The result was three copies of the `adr` skill, three of
`git-commit`, and two agents both named `tester` doing different jobs. Some of
that divergence was correct: `git-commit` disagreed about conventional-commit
prefixes because the repos genuinely disagree. The defect was not the difference
but that it was maintained by copying.

Separately, ADR-0023 kept the delegation and model-selection policy in
`CLAUDE.md`, arguing that trigger-scoped rules are inert for a reader they do not
apply to. That reasoning weighed `CLAUDE.md` against an extracted agent role and
did not consider the third option. Context files, `.claude/rules/` and imports
reach every subagent with no opt-out -- only built-in `Explore` and `Plan` skip
them, and that is not configurable. A skill costs its `description` until it
fires. Seven lines of delegation policy were therefore shipping into every spawn,
including agents that never delegate.

## Decision

Two tiers, one placement question: **would this sentence be false in another
project?** Yes places it in the project tier, no in the user tier
(`.config/agents/`, symlinked into `~/.claude/`). When in doubt, go narrower.

Content that should not reach every subagent goes in a skill body, because only
skills load on demand. The delegation policy moves out of `GLOBAL.md` into a
`delegation` skill accordingly, reversing ADR-0023.

A user-tier skill must work in a repo that has never seen it -- no pre-existing
directory, no setup step -- and references project facts by generic phrase with a
documented fallback, so a repo that declares nothing still behaves predictably.

The full doctrine, twelve rules each naming the failure it prevents, lives in
`agents/skills/harness-audit/design-rules.md`. The audit beside it enforces them.

## Consequences

One copy of each generic skill, at the tier where it is true. Adding one reaches
every project at once, which is what makes the tier worth having.
`~/.claude/skills` resolves to content for the first time; it previously pointed
at an empty directory and loaded nothing.

`GLOBAL.md` drops from 25 lines to 18, and the delegation policy is absent from
subagents rather than merely inert in them. ADR-0023's observation that the rules
are also correct for a subagent that delegates further still holds -- subagents
do get the Agent tool -- but a skill serves that case too.

Doctrine now has two homes and the boundary needs watching: ADRs record a
decision at a moment and are immutable, `design-rules.md` is current practice and
gets edited. The same split as ADR-0022 drew between `docs/adr/` and
`ENVIRONMENT_ARCHITECTURE.md`, one level in. If the two disagree, the ADR is
history and the rules file is policy.

Cost: the delegation policy now fires on a description match rather than being
unconditionally present. The failure is soft -- a worse model choice, not a wrong
action -- but it is a probability where there was a certainty.

The placement question is a judgment applied per file, with nothing enforcing it
mechanically. `harness-audit` is the compensating control, and it only helps if
it is actually run.
