---
name: delegation
user-invocable: false
description: Names the subagents and what each is for, picks one by footprint and a model by task shape, and decides whether the handoff pays for its cold start. Use before spawning any subagent, when a task looks big enough to hand off but it is not obvious that it should be, and when you need to know which agents exist.
---

# Delegation

## Does this pay?

Delegation buys context isolation and pays a cold start: the subagent re-derives everything from its prompt alone.
Gate on footprint -- what the work leaves in the caller's context -- not on the size of the thinking, and not on whether it is "implementation".

A mechanical rename across ten files is a loss to keep: the reasoning is nil, the diff output is not.
A one-line fix in a file already open is a loss to send.
Bulk output read once and never again -- a test failure, a build log, a directory crawl, a fetched page -- is the strongest signal there is.

Re-decide mid-task when the estimate turns out wrong: work kept that has grown goes out at that point.
The reads already done argue for handing off, not against it.

Resume a named agent with `SendMessage` when the follow-up needs what that agent learned and disk does not show; otherwise spawn fresh.
Work returned undone -- out of scope, blocked, refused -- resumes rather than respawns.

The web cannot be sized before it arrives, so it splits on whether the question is bounded.
`WebFetch` against a URL in hand, answering one named question, stays here.
Anything where which pages hold the answer is still unknown goes to `explorer` -- a `WebSearch`, a claim needing two sources agreed against each other, an issue tracker read down to its resolution.
Unclear cases go out.

## Fanning out writers

Readers parallelise freely.
Writers do not: two agents editing one tree destroy each other's verification, one running the check while the other's half-finished edits sit on disk.
Ordering the commits does not fix it.

Writers that must run at once each get `isolation: worktree` at the spawn, per call -- the serial case is the common one and should not pay for it.
Nothing brings those branches back, and a cleanup sweep deletes unmerged ones (anthropics/claude-code#38287), so plan the return as part of the fan-out:

- Scope them disjoint.
  Two briefs reaching the same files means the work was never parallel.
- Merge on return, not at the end of the session.
- Merge one, then rebase the rest onto the updated base.
- Reconciling goes out like any other work, carrying what each branch was for -- that is what decides a conflict, and it is in neither diff.

## Pick the agent by footprint

`developer` implements -- a self-contained change with a clear spec and an obvious way to verify it.
`explorer` finds things out -- enumeration and retrieval over a large surface, reliable at finding, listing and copying, weak at deciding.
`tester` verifies against something running.
`auditor` judges whether something written or proposed holds up, where being wrong is expensive.
`documenter` writes down what you already decided, across however many files it reaches -- what to write is settled and only applying it is left.

`leader` is the sixth, and is not on this list: it is the main-agent mode for a project (`claude --agent leader`), never a spawn.
A subagent that wants what `leader` does wants to hand the work back to its caller.

Each brief stands alone -- these agents have no memory of the conversation that spawned them.

## The agent carries its model

Each agent is pinned to the model its work needs, so choosing the agent has already chosen the model.
Pass no `model:` on a spawn; passing one discards the pin.
Reach for it only to go cheaper than the pin -- work that seems to need a dearer model than the agent carries is work for a different agent.

A verdict is what no check can settle for you.
Checking a written spec against a tree -- which findings landed, which files changed, whether a claim still holds at the line it names -- is retrieval: run the check first, then send the reading to `explorer`.

A built-in carries no pin, so `general-purpose` is the one spawn where the model is yours to name.

Delegate the legwork freely.
Judgment delegates only upward -- to an agent at least as capable as you, and it returns as a verdict, not a decision.
Whoever is deciding still decides.

Forks inherit the caller's model and ignore a `model` override, so spawn fresh for cheap work rather than forking.

## Write the prompt to stand alone

State what is under test or under construction, what counts as done, and any constraint the agent cannot infer.

When delegating skill-governed work, name the skill in the brief for the subagent to read.
Do not open `SKILL.md` or its supporting files before spawning.

Name what has already been tried and failed, or say that nothing has.
A subagent cannot know it is repeating a dead end already walked, and will spend the whole task doing it.

Require a distilled return -- findings and file paths, not raw output.
A subagent that pastes its transcript back has cost more than it saved.

Require it to mark what it ran apart from what it read.
A claim it executed comes back with the evidence that decided it and is worth what the run is worth; a claim it inferred from a doc reads identically and is worth what the doc is worth.
Asking for the line keeps the distinction free -- the agent already knows which it did, and the caller cannot tell afterwards without doing the work again.

A young project makes briefs longer, not shorter: a mature repository tells a subagent what it needs through `CLAUDE.md` and its records, a two-day-old one tells it nothing.

The second time the same fact goes into a brief, it has earned a line in `CLAUDE.md`.
Propose that line and wait for the user to take it -- two tasks that happened to rhyme look identical to a convention from here, and a wrong one lands in every spawn from then on.

## Nesting

Check an agent holds `Agent` before briefing it to fan out: an explicit `tools:` list grants only what it names (tested, v2.1.223), and an agent without it works serially rather than reporting that it cannot.
A grandchild's results are unreliable once the parent has finished, so keep chains short and let each level return before the one above.
