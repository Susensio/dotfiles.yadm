---
description: Audits this repo's agent harness and reports what's broken, misfiled, or unread. Use when agents ignore their context files, or after adding agents, skills, or decision records.
allowed-tools: Read, Grep, Glob, Bash
argument-hint: [path to audit, defaults to repo root + ~/.claude]
---

# Harness audit

Audit the agent harness at $ARGUMENTS (default: this repo plus `~/.claude`).

Produce a report. Change nothing unless asked afterwards. The only
commands you run that touch state are the project's own done-when
commands in Step 2; everything else is read-only inspection.

## How to report a finding

Every finding has three parts:

1. **Where** — a file, a line, or the command you ran.
2. **What breaks** — the consequence, in one clause. Not "this is wrong"
   but what goes wrong because of it.
3. **The fix** — one line.

Without part 2 the user can't judge whether to accept the finding, so
drop any finding you can't complete.

Mark with `?` anything you're unsure about, and say why. A harness
reflects choices made for reasons not visible in the files: an unusual
structure may be deliberate. Report what you observe and let the user
decide — don't assume a deviation is an error.

## Step 0 — Inventory, then decide how hard to look

Read: `AGENTS.md`, `CLAUDE.md`, nested `**/AGENTS.md`, `.claude/agents/`,
`.claude/skills/`, `.claude/settings*.json`, `.claude/agent-memory/`,
decision records (`decisions/`, `docs/adr/`, `rfcs/`), `specs/`, and the
`~/.claude/` equivalents. Check nested `**/.claude/` as well — in a
monorepo the per-app harness lives there. Note line counts, git-tracked
status, and agent count.

If the harness is fewer than ~5 files and the root context file is under
50 lines, run Steps 1 to 3 only, then stop. A small harness has little
surface for the later checks, and findings produced anyway will be noise.
A clean audit is a valid result.

## Step 1 — Loadability

*Mechanism: nothing reports a file that failed to load. The harness is
silent on success and silent on failure, so an unloadable instruction is
indistinguishable from an obeyed one. Every later step judges content
that may never reach a model at all — so run this first.*

1. Resolve every harness symlink (`readlink -f`). A dangling link drops a
   whole category with no warning.
2. **Every symlinked directory is non-empty.** An intact link to an empty
   directory passes `ls -l` and loads nothing.
3. Each skill directory has `SKILL.md`; each agent and command file is
   `.md` with parseable frontmatter and a non-empty `description`. The
   loader skips the rest in silence — stray dotdirs and editor backups
   included.
4. `settings*.json` parse (`jq .`). A malformed settings file is dropped
   whole, and every permission and hook in it stops applying. Check hook
   interpreters and script paths exist and are executable.
5. Frontmatter `name` matches the filename or directory name.
6. Harness files inside a repo: tracked, or deliberately ignored?
   `git check-ignore -v` and `git ls-files --error-unmatch`. Untracked
   and un-ignored means the harness exists on one machine and is one
   `clean` from gone.

Findings here outrank everything below. Name the source path the user
edits, never the symlink.

## Step 2 — Verification

*Mechanism: an agent can't observe the running system. Without commands
to run, it judges success by whether the diff looks plausible, so failures
are reported as completions.*

1. Find the done-when / definition-of-done block. If there isn't one,
   report that first — the other steps concern efficiency, this one
   concerns correctness.
2. Run the commands. Report each exit code.
3. Flag any that don't exist, need services that aren't running, are
   long-running (dev servers and watchers hang an agent and consume its
   context), or pass unconditionally.
4. Say whether the set would catch a plausible failure of this project.

## Step 3 — Staleness

*Mechanism: a human is skeptical of a doc that looks wrong; an agent
reading it on every request is not. It acts on stale content with the
same confidence as fresh.*

1. Every path named in an always-loaded file: does it resolve? Report
   directory trees in context files — paths move, and the agent can
   search instead.
2. Cross-check stated versions against lockfiles and manifests; check
   named commands exist.
3. Decision records the codebase no longer follows, and records
   superseded by a later one without a status line.
4. Specs for shipped work that no longer match the tests — an agent
   can't distinguish a stale spec from a current one.
5. Instructions requiring automation no instruction can supply. "Always
   run X after Y", "each time Z happens" — a context file can't fire on
   an event, only a hook can. Flag as unenforceable-as-written and name
   the hook that would implement it.

## Step 4 — Budget

*Mechanism: always-loaded files load once per agent, not once per
session. Past the instruction limit the model follows the tail
inconsistently, and the tail is what was added most recently.*

1. Report root context lines × (agent count + 1).
2. Flag a root file over ~150 lines, naming its three largest sections.
3. Flag content in `~/.claude/CLAUDE.md` that applies to only one
   language or one kind of work; it loads in every session of every
   project.
4. Sum every agent and skill `description:` — all of them load before
   any one is chosen. Flag any carrying procedure (steps, commands, an
   inline grep); that's body content taxing every session. Step 6 checks
   their form.

## Step 5 — Misfiling

*Mechanism: a subagent is a container — it costs a handoff, where the
session collapses to one summary. A skill is content — it costs context
when it loads. Misfiling means paying the wrong cost.*

**Agent that could be a skill.** An agent's container is justified if any
of these hold: it reads far more than it reports; it needs different
tools or permissions; it benefits from not having seen something; it runs
in parallel; it's pinned to a cheaper model; it carries an MCP server
whose tool descriptions would otherwise load in the main context. If none
hold, its value is its prompt text, which a skill delivers without the
handoff. Domain-named agents (`frontend`, `python-dev`) are worth checking
against this list — they're legitimate when the domain brings tooling with
it, not when the difference is only the prompt.

**Skill that could be an agent.** A skill whose steps are dominated by
reading rather than knowing — the reading lands in the main context.

**Either that could be a line in AGENTS.md.** Content that would be false
in another project shouldn't sit in a portable file.

**Either that's in the wrong scope.** An agent or skill byte-identical
across several repos pays a copy-per-project tax: edits land in one copy,
and whatever regenerates them overwrites the rest. One that names this
project's paths or phases doesn't belong in `~/.claude/`, where its
description loads in every unrelated session. Step 4 asks this of context
files — ask it of agents and skills too.

**Either that could be nothing.** Content the model already applies by
default competes with its own correct behaviour for budget. Also flag
context files that read as machine-generated — generated context files
are associated with reduced performance and higher cost.

**Duplication.** An agent body restating a skill: the `skills` field
loads the skill at startup instead.

## Step 6 — Descriptions

*Mechanism: the `description:` frontmatter is the only part of an agent or
skill loaded before it's chosen. It's the trigger, not a label — one that
says only what the thing is leaves the model guessing when to reach for
it, and the thing never fires.*

Every agent and skill description, in this order:

1. **What it does** — third person, present tense. Not imperative
   ("Implement a task"), not a noun phrase ("Task implementer").
2. **When to use it** — an explicit trigger sentence. Name the situation
   that should summon it, not the category it belongs to.
3. **`proactively`, optionally** — include the word whenever the thing
   should fire without the user naming it. Absent, it only ever runs when
   invoked explicitly.

Shape to match:

> Implements one scoped, multi-file task with clear acceptance criteria.
> Use proactively for any code change beyond a quick edit.

Flag: a missing when-clause; imperative or noun-phrase openings; anything
meant to fire unprompted that never says proactively.

Then, across the whole set:

**Return shape — agents only.** The handoff collapses the subagent's
session to one summary, so the description says what comes back.
`tester`'s "reports a verdict, not a transcript" is the shape. A
description that names only the work leaves the caller unable to judge
whether the handoff is worth its cost.

**Disjointness.** For each pair, write the request that should summon one
of them. If it summons both, the model picks wrong or picks neither.
Report the pair, not the two descriptions separately.

**The user's own words.** A description carries the phrases someone would
actually type, not internal vocabulary. Quoted triggers — "report this to
<project>", "file a bug" — beat a category name.

**Length.** Two sentences, three at the outside. Step 4 counts the total.

**When not to use it.** Only where mis-firing is expensive or
destructive: `tester`'s "Never invoke it to touch live state" earns its
line. On a cheap skill a negative clause is wasted budget.

Reporting: collapse form violations into one finding naming the files.
A missing when-clause or an overlapping pair is ranked on its own.

## Step 7 — Ownership, triggers, memory

- Two agents instructed to write the same file.
- Implementer agents not barred from the decision-record directory, where
  records are meant to be append-only.
- Agents described as read-only whose tools include Edit or Write — note
  that setting `memory:` force-enables Read, Write and Edit.
- Decision numbers not referenced anywhere in the code: nothing prompts a
  reader at the moment the decision is being reversed.
- Files unmodified since creation (`git log`) and unreferenced by any
  other file. Name when each is read; if there's no such moment, say so.
- Rules living only in agent or auto memory, which is unreviewed; and
  whether a path exists for promoting them into reviewed docs.
- Committed files naming user-scoped agents or skills — these don't
  resolve on a fresh clone.

## Report

```
## Verdict
<2-3 sentences: what state the harness is in, and the biggest friction point>

## Loadability
<anything that doesn't reach a model, first and uncapped — a file that
never loads makes every judgment below it moot. Say "all N load" if clean>

## Verification
<each command, exit code, whether the set would catch a real failure>

## Findings
<max 10, ordered by how often each will bite:
 <file:line> — <what's wrong> → <what breaks> → <fix>   [? if uncertain]>

## Convert
<agents that could be skills, skills that could be agents, either that
could be a line in AGENTS.md — with the reason from Step 5>

## Delete
<with evidence: never modified, never referenced, no read trigger>

## Add
<usually zero or one, naming the failure it prevents>
```

Stop at ten findings; beyond that the user stops reading, so the extras
displace nothing and cost attention.

Deduplicate to root cause first, then count. One dead symlink that
orphans nine skills is one finding, not ten — nine of those would fill
the budget with a single fix.

## Closing paragraph

One paragraph, whichever applies:

- Step 2 found nothing runnable — say the other findings are secondary
  until that's fixed.
- Harness size is disproportionate to codebase size, in either direction.
- Files never edited since creation, decision records nothing points at,
  agents never invoked — a design that hasn't been exercised yet.
- None of the above — say the harness looks sound and stop.

Then state the smallest version of this harness that would still do its
job, so the difference is visible.
