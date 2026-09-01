# ADR-0033: Reserve the leader for real projects instead of every session

Status: Accepted
Date: 2026-08-24
Supersedes: [ADR-0032](0032-leader-main-agent.md)

## Context

ADR-0032 made `leader` the main agent everywhere, set by `"agent": "leader"` at the user tier.
That setting was never applied: `settings.json` carried no `agent` key, so the decision existed as a record and not as a running configuration.
What did exist was the worst of both readings -- `leader` sat in `agents/`, so it registered as a spawnable subagent while its own description said "a project's main agent, not a subagent", and the deny entry meant to keep the main agent out of the roster still named `orchestrator`, an agent deleted from the tree.

Reading `leader` against a small session made the mismatch concrete.
Its delegation logic was already conditional and correct -- "once doing them here would drag their output into this context", "whether a handoff pays at all", "what you keep is a judgement, not a limit".
The cost was in two rituals stated unconditionally: reading the project's record at the start of every turn, and routing anything that builds, runs or tests to `tester`.
Both are right for a repository with a record and a declared check.
On a one-line tmux fix they are overhead paid every turn, and an instruction that gets ignored teaches that instructions here are advisory.

The alternative to reserving it was to condition those rituals and keep the ubiquity.
Rejected because the hedging compounds: a leader written to be safe in a session with no record, no check and no plan says progressively less about the case it exists for, and the sharpest thing it owns -- reconciling what two subagents each brought back -- never arises in the sessions the hedging was for.

Underneath this is that the default session is not a weak fallback.
Shaped by `CLAUDE.md` and the skills, it implements, verifies, searches and can spawn an `auditor` more capable than itself when it is stuck.
Ubiquity was buying one architecture at the price of forcing a project-shaped workflow onto work that has no project.

## Decision

`leader` is invoked deliberately for project work -- `claude --agent leader`, or `"agent": "leader"` in that project's own `.claude/settings.json` -- and is not set at the user tier.
`Agent(leader)` is denied, so it is never spawned as a subagent and its description stops contradicting the roster it appeared in.

Everything else runs as the default session, which delegates on judgement rather than by rule.
The line between them is documentation discipline, not capability: `leader` follows where each piece of information goes, autoloading the `project-record` and `delegation` skills; the default session reads a project's docs and infers how to use them.

Freed from covering the trivial case, `leader` keeps three things and delegates the rest: a quick check whose output it can bound, a quick fix it can make and verify faster than it could brief, and reconciling what two subagents each returned -- which exists only where the returns meet and so cannot be delegated at all.

## Consequences

Two modes, chosen at launch, and choosing is manual.
Getting it wrong degrades gracefully in one direction only: a project session started as the default behaves like a capable generalist that delegates less, while a trivial session started as `leader` pays the record-and-check ritual for nothing.

`leader` can state its rules unconditionally again, because the sessions that made them awkward no longer reach it.
The record cadence became "when you do not already know what it says", which is a rhythm rather than a hedge.

`CLAUDE.md` now has to carry what both modes need, and it reaches every subagent with no opt-out, so main-session-only content still has nowhere cheap to sit.
ADR-0032's finding stands: the pronoun test is the tell, and content that only makes sense to whoever is talking to the user belongs in `leader` or in `outputStyle`, not there.

Enforcement remains convention.
`leader` still declares no `tools:` list and holds the full grant, for the reason ADR-0032 gave -- a removed tool has no override, and the one agent that talks to the user needs an escape hatch.
`Agent(name)` would be enforced on it, since the allowlist form binds on a main-thread agent and is ignored in a subagent definition, but restricting the roster contradicts the full-grant reasoning and is deliberately not done.

The `claude2agy` addon keeps `main_agent: "leader"` for its own target, which is unaffected: this decision is about which Claude Code sessions get a leader, not about what the compiled Antigravity harness does.
