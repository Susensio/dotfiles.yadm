---
name: harness-design
user-invocable: false
description: Use before writing or editing any agent, skill, rule or context file, and when deciding where new harness content lives. Covers slot choice, naming, description and enforcement.
---

# Harness design

Doctrine for building the harness.
The `audit-harness` skill enforces these; this file says why they exist.
Each rule states the current conclusion and the failure it prevents; the investigation behind it lives in the commit or ADR that changed it.

## R-one-slot. One fact, one slot.

| The content | Slot |
|---|---|
| A container property -- tool scoping, a model pin, context isolation, parallelism, cold-start independence | agent frontmatter |
| Knowledge Claude needs at one particular moment | skill body |
| A standard that a file path or extension decides | `.claude/rules/` with `paths:` |
| Something true every turn of every session | `CLAUDE.md` |
| Something a person reads | `docs/` |

One copy per reader.
The same name in two tiers is a silent override with no merge, no `extends:`.
Fix by deleting, never by syncing.

**An agent is a container, never content.**
Only a container property justifies one; value that is only prompt text belongs in a skill, which delivers it without a handoff.
So an agent never names a domain: generic container, caller-supplied binding, domain knowledge arriving through the skill the caller names.
A worked example naming a domain is fine (`auditor` citing `audit-harness`); the bar is on binding, not illustration.
The `skills:` field injects a full SKILL.md at startup, so it preloads only what is true on every invocation.
It fires on a spawn and not on `--agent`, so a launch-only agent names its skills through a trigger instead ([`references/runtime-facts.md`](references/runtime-facts.md)).

**Load cost decides skill against rule against `CLAUDE.md`.**
`CLAUDE.md` and its imports reach every subagent; only built-in `Explore` and `Plan` skip them.
`.claude/rules/` splits on `paths:` (tested, v2.1.238): a scoped rule loads when a matching file is read, an unscoped one at session start, and **both reach a subagent**.
So the choice is context cost, not reach: an unscoped rule sits in every session from the first turn.
The glob resolves against the project, and a matching file outside the tree did not fire the rule.
A rule added mid-session waits for the next session if unscoped, loads on the next matching read if scoped; probe with a fresh session.
Under `claude -p` a scoped rule did not load at all.
Write the glob, or write `CLAUDE.md`.
Between skill and rule, follow the trigger: a skill when applying it takes judgement, a path-scoped rule when a path or extension decides.
Past roughly 500 lines a skill's detail goes in a sibling file loaded on demand.

One exception (ADR-0030): content whose job is to counter an instruction present every turn cannot be a skill, because a skill loads only once the decision is being taken.
The delegation trigger sits in the user-tier `CLAUDE.md` for that reason -- the trigger alone, never the policy.

**Audience decides skill against doc.**
A skill makes Claude act correctly; a doc is for a person.
A project's own state -- where its requirements, plan and notes live, what command verifies it -- is a doc in `docs/`.
A procedure both audiences run (a deployment, a release) exists in both forms: the doc is the source of truth, and the skill holds the trigger and a pointer, never a second copy of the steps.
A procedure only Claude runs stays whole in the skill.

**Tier -- would this sentence be false in another project?**
Yes, project tier; no, user tier.
When in doubt, go narrower: wrongly local costs one duplicate later, wrongly hoisted is wrong everywhere at once.
A user-tier skill works in a repo that has never seen it -- no pre-existing directory, config file or setup step.

*Failure it prevents:* role agents differing only in domain nouns; drifting copies of one skill; a project agent silently shadowing a user-level one.
Delegation policy shipped into agents that cannot delegate -- and context files arrive under an injected reminder that they may be irrelevant, so an off-topic rule teaches the model to discount the rules beside it.
A runbook copied into a skill body, where the copy nobody reads goes stale.

## R-harness-map. `docs/harness.md` describes the global userspace harness; whoever changes the harness updates it.

Adding or removing an entry point, a subagent, or a hook -- anything that changes what a reader of `docs/harness.md` believes -- carries the doc edit in the same change.
It describes the global `~/.config/claude/`, not a project-local `.claude/`.
Skip the edit only where the change is invisible from its altitude: rewording a skill's internals, not what it is for or when it fires.

*Failure it prevents:* a stale map that reads as authoritative, naming an agent already deleted.

## R-trigger. A description is a trigger, not a label; a body is instructions, not commentary.

The description says what it does, then when to use it, and for an agent what comes back.
It is the only text loaded before the thing is chosen, read by the caller.
The body is read by the thing itself, executing: it states the rule and stops.
Explanations of how the harness behaves belong in this file, not scattered through the things it governs.

A fact serving both readers belongs in both, worded for each -- a read-only agent advertises `Read-only: it judges, never changes` to the caller and states the contract with its loopholes to itself.
Two copies serving the same reader is a duplicate.
Word each rule so someone can apply it cold.

Cut restatement of a sibling file, commentary on harness behaviour, hedges ("really", "already", "actually", "basically", "essentially") and the closing clause that re-sells a stated rule.

Keep:

- The worked example that shows the shape of a right answer.
- The concrete fallback and named default (R-fallback).
- The specific trap, named: "Stage by explicit path, never `git add .`" survives compression; "commit carefully" does not.
- The reason, where it makes the rule applied rather than merely agreed with.
- The test, where the rule is behavioural: "every changed line traces to something the request asked for" can be failed; "make surgical changes" cannot.

For document craft consult `writing-for-agents`.

*Failure it prevents:* a skill that never fires because its description says what it is, not when to reach for it; agent bodies that grow into essays paid for on every spawn; compression that strips the example or fallback and leaves a slogan.

## R-enforcement. Enforcement sits at the fastest layer that can hold it.

Frontmatter looks binding and is not: several fields read as a restriction and grant everything, and the ones that fail open fail silently.
[`references/runtime-facts.md`](references/runtime-facts.md) says which field does what -- read it before claiming a grant holds.

A read-only agent is a convention it keeps, not a cage: a `tools:` allowlist omitting `Write` and `Edit`, and the contract in the body's first paragraph, naming the obvious loophole -- no shell redirect standing in for `Write`.
`disallowedTools: Write, Edit` beside such an allowlist removes nothing; it reads as a second guardrail and is none.
The session sandbox cannot separate a read-only agent from its caller.
Subagents get no memory: knowledge worth reading is worth reviewing, so it belongs in a skill or context file.
Where unavoidable, `memory: project`, never `user` or `local`.

Where a rule is mechanically decidable -- a name collision, a parenthesised specifier, a file that does not parse -- mechanize it and delete the prose asking an agent to check.
Fastest first: a `PreToolUse` hook that blocks before the edit, a `PostToolUse` hook that returns the violation, a pre-commit hook, CI, a reader.
Each step down costs a turn, a push or a review cycle before the agent learns it was wrong.

A mechanism holds only where both are true:

- **It survives the agent.** Where the cheapest fix for a failing check is editing the check, that is the fix made.
  Linter config, hook scripts and the CI workflow are protected, or nothing is.
- **Its message carries the fix.** An agent can skip a doc, not the text a failing check prints.
  That text names what to do instead, and the rule it came from.

The audit holds what no mechanism can decide.

*Failure it prevents:* believing an agent is read-only or model-pinned because frontmatter says something never parsed; a convention enforced only in review; a rule an agent satisfies by turning the rule off.

## R-fallback. Declare with fallback.

Reference project facts by generic phrase plus a documented default.
A missing declaration yields a known fallback or an explicit stop, never a guess.
Description and body are one contract read from opposite ends: a description must not demand what the body defaults, or default what the body demands.

*Failure it prevents:* a generic skill in a repo that declares nothing, improvising a convention; a file that only says "ask", turning every under-specified handoff into a cold round-trip.

## R-probe. Verify by use, under the sandbox, never by asking.

Tools reading credentials from a keyring, a socket or the session bus behave differently for an agent than for you.
A skill shelling out to one is not working until run the way an agent will run it, with a real call, not a status subcommand: `gh auth status` reports failure while `gh search` succeeds, because they read different credentials.

An agent's account of its own tools is generated text, not a reading of the runtime: one declaring `Grep, Glob` reported neither and used both.
Confirm a grant by having the agent **use** the tool, withholding whatever would let it reach the answer another way, so an absence means what it looks like.

*Failure it prevents:* `gh`-dependent skills that pass by hand and fail for every subagent.

## R-stamp. Every runtime claim carries the version it was tested against.

`(tested, v2.1.238)`, `(probed, ...)` for a live canary, `(documented, ...)` for a doc citation.
A stamp well behind `claude --version` marks a rule to re-probe.
Stamped facts live in [`references/runtime-facts.md`](references/runtime-facts.md), one line each, cited from wherever they are used, so a fact that moves upstream is corrected in one place.

*Failure it prevents:* a runtime claim trusted long after the release that changed it.

## R-name. The name follows the thing's nature, and invocability follows the name.

Lowercase, hyphenated, and:

- **Agents are persons** -- `tester`, `auditor`.
- **Knowledge skills take a noun** -- `delegation`, `tmux-config` -- and set `user-invocable: false`.
- **Action skills take an imperative** -- `audit-harness`, `report-issue` -- and stay invocable both ways.

Commands are a subset of skills; write skills.
A noun-named skill that is user-invocable, or an imperative-named one nothing can trigger, is misfiled.

*Failure it prevents:* a knowledge skill cluttering the `/` menu, and an action nobody can reach because its name reads like a topic.

## R-in-time. An instruction reaches an agent that can act on it, in time to act on it.

`CLAUDE.md` and its imports reach every subagent, and a skill reaches whoever invokes it, so an instruction lands on agents whose `tools:` list was never checked against it.
An agent that cannot follow one works around it silently.
Either the rule names the condition under which it applies, or the grant changes to match.

Arrival time is half the test.
Content that loads only once the decision it governs is being taken has not been delivered: the trigger sits upstream of the choice, or the content loads unconditionally (ADR-0030).

A handoff is the same test read forward: the agent named exists, the agent naming it holds `Agent`, and the brief carries what the target's description demands (R-fallback).
A path can close on itself -- two files each naming the other as the prerequisite, or an agent handing work back to the one that briefed it.
A cycle costs turns rather than failing, so declare one end the entry.

R-one-slot catches the second copy; this asks whether the one copy landed where it can be executed.

*Failure it prevents:* every file valid, every reference resolving, the chain dead anyway -- an agent briefed to fan out with no `Agent` tool.
And one concept under two names, where the agent that learned the other name greps, finds nothing, and concludes it does not exist.
