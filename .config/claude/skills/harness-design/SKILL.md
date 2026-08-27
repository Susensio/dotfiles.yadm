---
name: harness-design
user-invocable: false
description: Which slot a piece of harness content belongs in -- agent, skill, path-scoped rule, context file or doc -- and what its name, description and enforcement have to do once it is there. Use before writing or editing any agent, skill, rule or context file, and when deciding where something new should live.
---


# Harness design

Doctrine for building the harness.
The `audit-harness` skill enforces these; this file says why they exist.
A rule that cannot name the failure it prevents does not belong here.

Each rule states the current conclusion and the failure it prevents, and stops there.
The investigation behind it -- what was probed, which hypothesis died -- belongs in the commit that changed the rule, or in an ADR when a decision was reversed.
Provenance read here on every audit costs more than it informs; `git log -p` still has it when the rule looks wrong.

## R-one-slot. One fact, one slot.

Every piece of harness content has one home, and which one follows from what the content is:

| The content | Slot |
|---|---|
| A container property -- tool scoping, a model pin, context isolation, parallelism, cold-start independence | agent frontmatter |
| Knowledge Claude needs at one particular moment | skill body |
| A standard that a file path or extension decides | `.claude/rules/` with `paths:` |
| Something true every turn of every session | `CLAUDE.md` |
| Something a person reads | `docs/` |

One copy per reader.
The same name in two tiers is a silent override with no merge -- there is no `extends:`, no partial frontmatter override.
Fix by deleting, never by syncing.

**An agent is a container, never content.**
An agent is justified only by a container property from the table above; value that is only prompt text belongs in a skill, which delivers it without paying for a handoff.
It follows that an agent never names a domain: generic container, caller-supplied binding, domain knowledge arriving through the skill the caller names.
A worked example naming a domain is fine -- `auditor` cites `audit-harness` to show what "the skill carrying the checks" means -- because the bar is on *binding*, not illustration: a second domain must work without editing the agent.
The `skills:` field is the back door, since it injects a full SKILL.md at startup, so it preloads only what is true on every invocation.
It fires on a spawn and not on `--agent`, so a launch-only agent has to name its skills through a trigger instead ([`references/runtime-facts.md`](references/runtime-facts.md)).

**Load cost decides skill against rule against `CLAUDE.md`.**
`CLAUDE.md` and its imports reach every subagent with no opt-out; built-in `Explore` and `Plan` are the only agents that skip them, and that is not configurable.
`.claude/rules/` splits on `paths:` (tested, v2.1.238): a rule carrying it loads when a matching file is read, a rule without it loads at session start, and **both reach a subagent** -- the unscoped one always, the scoped one once the subagent reads a match.
So the choice is context cost, not reach: an unscoped rule sits in every session from the first turn whether or not it applies, at both tiers.
The glob resolves against the project; a matching file outside the tree did not fire the rule.

A rule added mid-session splits the same way, and this is what makes the difference easy to mis-test: an unscoped rule is not picked up until the next session, while a scoped one loads the next time a matching file is read.
Probe with a fresh session, never one already running.
Under `claude -p` a scoped rule did not load at all, even after a matching file was read.
Write the glob, or write `CLAUDE.md`.
Between the remaining two, follow the trigger: a skill when deciding it applies takes judgement, a path-scoped rule when a path or extension decides it.
A skill pays its whole cost on invocation, so past roughly 500 lines the detail belongs in a sibling file it loads on demand.

One exception (ADR-0030): content whose job is to counter an instruction present every turn cannot be a skill, because a skill loads only once the decision it governs is already being taken.
The delegation trigger sits in `GLOBAL.md` for that reason -- the trigger alone, never the policy behind it.

**Audience decides skill against doc.**
A skill exists to make Claude act correctly; a doc exists for a person to read.
Audience decides the form -- load mechanics change with the tooling, audience does not.
A skill's supporting files follow the skill: they are knowledge, shelved where it can reach them, not documentation that happens to live there.
A project's own state -- where its requirements, plan and notes live, what command verifies it -- is user-facing, so it is a doc in `docs/`.
Some procedures have both audiences: a deployment, a release, a suite a person also runs by hand.
Then both forms exist -- the doc in `docs/` is the source of truth, and the skill holds the trigger and a pointer to it, never a second copy of the steps.
A procedure only Claude ever runs stays whole in the skill.

**Tier -- would this sentence be false in another project?**
Yes, project tier.
No, user tier.
When in doubt, go narrower: a rule wrongly kept local costs one duplicate later; wrongly hoisted, it is wrong everywhere immediately.
A user-tier skill works in a repo that has never seen it -- no pre-existing directory, no config file, no setup step.
That is what makes the tier pluggable: a change lands once and every project has it, including one created tomorrow.

*Failure it prevents:* role agents that differ only in domain nouns -- `backend-developer` and `frontend-developer` stamped from one template, word for word identical apart from the stack they name.
Three copies of one skill drifting apart, and a project agent silently shadowing a user-level one.
Delegation policy shipped into every spawn, including the agents that cannot delegate -- and worse than the token cost, context files arrive under an injected reminder that this content may not be relevant and should not be acted on unless it clearly is, so an off-topic rule teaches the model to discount the rules sitting beside it.
Project state buried under `.claude/` where someone returning to the repo will not find it, and a runbook copied into a skill body, where the copy the person does not read is the copy that goes stale.

## R-trigger. A description is a trigger, not a label; a body is instructions, not commentary.

The description says what it does, then when to use it, and for an agent what comes back.
It is the only text loaded before the thing is chosen.

The body states the rule and stops.
An agent following an instruction does not need to know which mechanism failed to enforce it -- explanations of how the harness behaves belong in this file, not scattered through the things it governs.

The two have different readers: the description is read by the caller choosing whether to reach for this at all, the body by the thing itself, executing.
A fact that does both jobs belongs in both, worded for its reader -- a read-only agent advertises `Read-only: it judges, never changes` to the caller, and states the contract with its loopholes to itself.
That is the one copy per reader R-one-slot allows; two copies serving the same reader is a duplicate, however far apart they sit.

The rule itself gets worded as an instruction someone has to apply cold, without the file it describes in front of them.
That is a higher floor than a comment sitting beside the code it explains -- compress toward it, do not arrive at it.

Cut:

- Restatement of a sibling file.
  A rule repeated in the agent that loads the skill carrying it is a duplicate, one file down.
- Commentary on how the harness behaves, which belongs here.
- Hedges -- "really", "already", "actually", "basically", "essentially" -- and the closing clause that re-sells a rule already stated.

Keep:

- The worked example that shows the shape of a right answer.
- The concrete fallback and the named default, so a caller who supplied neither still lands somewhere known (R-fallback).
- The specific trap, named.
  "Stage by explicit path, never `git add .`" survives compression; "commit carefully" does not.
- The reason, where the reason is what makes the rule applied correctly rather than merely agreed with.
- The test, where the rule is behavioural and prose is all that holds it.
  "Every changed line traces to something the request asked for" can be applied to a diff; "make surgical changes" cannot be failed, so it is followed at random.

For document craft -- progressive disclosure, leading words, unambiguous completion bounds, and pruning no-ops -- consult the `writing-for-agents` skill.

*Failure it prevents:* a skill that never fires because its description says what it is rather than when to reach for it, and agent bodies that grow into essays about the harness, paid for on every spawn.
On the other side, compression that strips the example or the fallback an agent needed and leaves a slogan it cannot act on.
And a one-word edit reflowing a whole paragraph, so review sees a rewritten block and cannot tell which sentence actually changed.

## R-enforcement. Enforcement sits at the fastest layer that can hold it.

Frontmatter looks binding and is not: several fields read as a restriction and grant everything, and the ones that fail open fail silently.
Which field does what, and what a built-in's absence from the session list does and does not prove, are in [`references/runtime-facts.md`](references/runtime-facts.md) -- read it before claiming a grant holds.

So a read-only agent is a convention it keeps, not a cage: give it a `tools:` allowlist that omits `Write` and `Edit`, and state the contract in the body's first paragraph, naming the obvious loophole -- no shell redirect standing in for `Write`.
Adding `disallowedTools: Write, Edit` beside such an allowlist removes nothing that was granted; it reads as a second guardrail and is none, which is worse than leaving the contract to the prose that does cover the loophole.
The rest rests on the agent.
The session sandbox is real enforcement but session-wide, so it cannot separate a read-only agent from its caller.
For the same reason subagents get no memory: it is not shared with the main session, and knowledge worth reading is worth reviewing, so it belongs in a skill or a context file.
Where unavoidable, `memory: project` -- committed and reviewable -- never `user` or `local`.

Where a rule is mechanically decidable -- a name collision, a parenthesised specifier, a file that does not parse -- prose asking an agent to check it is the weakest available enforcement.
Mechanize it and delete the prose; do not keep both.
Fastest first: a `PreToolUse` hook that blocks before the edit, a `PostToolUse` hook that returns the violation, a pre-commit hook, CI, a reader.
Each step down costs a turn, a push, or a review cycle before the agent learns it was wrong, and by then it has built on the mistake.

A mechanism holds only where both are true:

- **It survives the agent.** Where the cheapest fix for a failing check is editing the check, that is the fix that gets made.
  The linter config, the hook scripts and the CI workflow are protected, or nothing is.
- **Its message carries the fix.** An agent can skip a doc; it cannot skip the text a failing check prints.
  That text names what to do instead, and the rule it came from.

The audit holds what is left: what no mechanism can decide.

*Failure it prevents:* believing an agent is read-only because its frontmatter says something that was never parsed, or that its model is fixed because the frontmatter names one.
A convention enforced only in review, rediscovered from scratch by every agent that hits it -- and a rule an agent satisfies by turning the rule off.

## R-fallback. Declare with fallback.

Reference project facts by generic phrase plus a documented default.
A missing declaration yields a known fallback or an explicit stop, never a guess.

The description and the body are one contract read from opposite ends: a caller obeys the description, the thing itself obeys the body.
So a description must not demand what the body defaults, or default what the body demands.

*Failure it prevents:* a generic skill dropped into a repo that declares nothing, improvising a convention instead of asking or defaulting.
A file that only ever says "ask" turns every under-specified handoff into a cold round-trip, paid at the caller's expense before any work starts.

## R-probe. Verify by use, under the sandbox, never by asking.

Tools that read credentials from a keyring, a socket, or the session bus behave differently for an agent than for you.
A skill that shells out to one is not working until it has been run the way an agent will run it.
Probe with a real call, not a status subcommand -- `gh auth status` reports failure while `gh search` succeeds, because they read different credentials.

An agent's account of its own tools is generated text, not a reading of the runtime: one declaring `Grep, Glob` reported neither and used both.
So confirm an effective grant by having the agent **use** the tool, never by asking it to list one, and withhold whatever would let it reach the answer another way, so an absence means what it looks like.

*Failure it prevents:* `gh`-dependent skills that pass by hand and fail for every subagent, indistinguishably from the tool being broken.
And a grant an agent cheerfully reports it does not have.

## R-stamp. Every runtime claim carries the version it was tested against.

`(tested, v2.1.238)`, or `(probed, ...)` for a live canary and `(documented, ...)` for a doc citation, so a reader can tell a rule that still holds from one that was true two releases ago.
A stamp well behind `claude --version` marks a rule to re-probe, not one to trust.

Stamped facts live together in [`references/runtime-facts.md`](references/runtime-facts.md), one line each, so a fact that moves upstream is corrected in one place and not chased through every file that leaned on it.
Anything asserting what the runtime does belongs there, cited from wherever it is used.

*Failure it prevents:* a runtime claim trusted long after the release that changed it, with nothing in the text to date it.

## R-name. The name follows the thing's nature, and invocability follows the name.

Lowercase, hyphenated.
Beyond that:

- **Agents are persons** -- `tester`, `auditor`.
- **Knowledge skills take a noun** -- `delegation`, `tmux-config` -- and set `user-invocable: false`.
  There is nothing to invoke; it is something Claude should know at the right moment.
- **Action skills take an imperative** -- `audit-harness`, `report-issue` -- and stay invocable both ways.

Commands are a subset of skills and add nothing a skill lacks.
Write skills.

The pairing is checkable: a noun-named skill that is user-invocable, or an imperative-named one nothing can trigger, is misfiled.

*Failure it prevents:* a knowledge skill cluttering the `/` menu with something nobody would type, and an action nobody can reach because its name reads like a topic.

## R-in-time. An instruction reaches an agent that can act on it, in time to act on it.

`CLAUDE.md` and its imports reach every subagent with no opt-out, and a skill reaches whoever invokes it, so an instruction lands on agents whose `tools:` list was never checked against it.
An agent that cannot follow one works around it silently; nothing reports the gap.
Either the rule names the condition under which it applies, so an agent outside that condition can tell it is outside, or the grant changes to match.

Arrival time is half the test.
Content that loads only once the decision it governs is being taken has not been delivered, however correct it is -- the trigger has to sit upstream of the choice, or the content has to load unconditionally (ADR-0030).

A handoff is the same test read forward: the agent named exists, the agent doing the naming holds `Agent`, and the brief carries what the target's description demands (R-fallback).
Read forward far enough and the path can close on itself -- each of two files naming the other as the prerequisite, or an agent handing work back to the one that briefed it.
A cycle costs turns rather than failing outright, so nothing surfaces it; one end has to be declared the entry.

This is not R-one-slot in another costume.
R-one-slot asks where a fact lives and catches the second copy; this asks whether the one copy landed somewhere it can be executed.
A rule can sit in exactly the right slot and still reach an agent with no tool to obey it.

*Failure it prevents:* every file valid, every reference resolving, and the chain dead anyway -- an agent briefed to fan out with no `Agent` tool, a research rule delivered to the agent that already holds the web tools and cannot hand anything on.
And the slower version: one concept under two names, where the agent that learned the other name greps for it, finds nothing, and concludes the thing does not exist.
