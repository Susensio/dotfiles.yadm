# ADR-0032: Run every project through a leader main agent instead of the default session

Status: Superseded by [ADR-0033](0033-leader-for-projects-not-every-session.md)
Date: 2026-08-24

## Context

ADR-0023 weighed extracting an orchestrator and declined, on the grounds that the policy in question was four bullets none of which invert by reader.
It left a trip-wire rather than a closed question: "reaching for 'you' to mean specifically the main session means the rule now belongs in an extracted role, and the split deferred here has to be done then."
ADR-0026 then superseded it on placement, moving the delegation policy into a skill; ADR-0030 moved the trigger back to `GLOBAL.md`.
Neither touched the deferral.

The trip-wire has tripped.
Several rules are now true for the main session and false inside a subagent: owning the project's record, running the check that closes the loop, writing ADRs, and deciding what gets delegated at all.
The pronoun test made the boundary visible rather than arguable -- `GLOBAL.md`'s personally-worded bullets ("reporting to me", "the size I asked for", "let me pick") were, without exception, the main-session-only ones, while every impersonal bullet was genuinely universal.

Two things also changed underneath the original reasoning.
The roster is six agents rather than two, so routing and ownership need a home that subagents do not pay for.
And `"agent": "<name>"` in `settings.json` runs the main thread as a named agent, per-project overridable, which ADR-0023 did not have available in the form it considered.

Against extraction: it adds a layer to maintain, it applies to a weekend spike as much as a mature repository, and the token saving is close to nothing, because the delegation trigger has to stay in `GLOBAL.md` regardless.

## Decision

`leader` is the main agent in every project, set by `"agent": "leader"` at the user tier and overridable per project.

It declares no `tools:` list, so it holds the full grant.
What it keeps versus delegates is a judgement it makes each time, never a capability it lacks -- a removed tool has no override, and the main session is the one agent that talks to the user and therefore needs an escape hatch.

It owns the project's record, closing the loop, ADR authorship, and the delegate-or-keep call.
Subagents own the doing, and `developer` commits its own finished work, because the order it did things in and which edits corrected earlier ones decide where one concern ends, and none of that survives being handed to anyone else.

Content that was main-session-only moved out of `GLOBAL.md` accordingly: commits to `leader`, agent-memory routing to the `project-record` skill, and concision toward the user to the `outputStyle` setting, which reaches the main conversation and not subagents.
The delegation trigger stays where ADR-0030 put it, unchanged: three agents now hold `Agent`, so a trigger written into `leader` alone would not reach the other two.

## Consequences

One architecture in every project, from a one-off spike to a mature repository, with only the documentation differing between them.
What makes that survivable is that every project fact is already referenced by generic phrase with a documented fallback (R4), so a repository declaring nothing still behaves.

`GLOBAL.md` drops from 25 lines to 12, and what left it stops reaching every spawn.
The saving is small and was never the point: the value is that main-session-only behaviour now has a correct home, instead of accreting in the one file that reaches every agent with no opt-out.

The leader is never chosen from a roster, so the naming rules that govern subagents do not constrain it -- its name is a settings key and nothing routes to it by description.

Enforcement is convention, not mechanism.
A leader holding every tool can do anything it is told not to, and R3 already records that frontmatter is not a cage.
The full grant makes that explicit rather than pretending otherwise.

Deliberately accepted, none of them fixable without a worse trade:

- The rule about building to the size asked for was dropped rather than reworded, because no version of it could be failed and R2 rejects a rule that is followed at random.
  Over-production in proposals and analysis is now caught by nothing; the code and report cases are covered by `coding` and by each agent's report contract.
- `documenter` receives two `GLOBAL.md` bullets it cannot act on, holding neither `Bash` nor web tools.
  Inert rather than misleading, and narrowing the rules to fit costs more than it saves.
- A project that does not want a leader has to say so in its own `settings.json`.
  The default is now opinionated where it was previously absent.
- `"agent"` applies the named agent's tool restrictions to the main session.
  `leader` declares none, so nothing is lost here -- but an agent that did declare a list would silently strip tools from the main session, including ones the session needs and the agent's author never considered.

Reversal is cheap: delete the settings key, and the agent file becomes an ordinary unused subagent.
Nothing else depends on it being the main one.

Not yet verified under the sandbox: `"agent"` is still unset, so the tool-restriction behaviour above is read from the documentation rather than observed (v2.1.238).
