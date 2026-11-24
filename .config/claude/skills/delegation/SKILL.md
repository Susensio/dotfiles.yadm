---
name: delegation
user-invocable: false
description: Use before spawning any subagent, when unsure whether a task is worth handing off, or to learn which agents exist. Picks agent by footprint and model by task shape.
---

# Delegation

## Does this pay?

Delegation buys context isolation and pays a cold start.
Gate on footprint -- what the work leaves in the caller's context -- not on the size of the thinking.
A mechanical rename across ten files is worth sending; a one-line fix in an open file is not.
Bulk output read once -- a test failure, build log, directory crawl, fetched page -- is the strongest signal.
Re-decide mid-task when the estimate was wrong: work that has grown goes out then.

Resume a named agent with `SendMessage` when the follow-up needs what it learned and disk does not show, and for work returned undone; otherwise spawn fresh.

Web: `WebFetch` on a URL in hand for one named question stays here.
Anything where which pages hold the answer is unknown -- `WebSearch`, cross-source claims, an issue read to resolution -- goes to `explorer`.

## Agents

- `developer` -- a self-contained change with a clear spec and an obvious check.
- `explorer` -- find, list, copy over a large surface; weak at deciding.
- `tester` -- verifies against something running.
- `auditor` -- judges whether written or proposed work holds up, where being wrong is expensive.
- `documenter` -- applies settled wording across many files.

`leader` is a main-agent mode (`claude --agent leader`, or `/act-as-leader`), never a spawn.
Checking a written spec against a tree is retrieval: run the check, then send the reading to `explorer`.
Judgment delegates only upward, returns as a verdict, and the caller still decides.

Each agent is pinned to its model.
Pass no `model:` on a spawn; it discards the pin, so use it only to go cheaper.
`general-purpose` carries no pin, so the model is yours to name there.
Forks inherit the caller's model and ignore `model`; spawn fresh for cheap work.

## Fanning out writers

Readers parallelise freely.
Writers that must run at once each get `isolation: worktree` per call; two writers in one tree break each other's verification.
Nothing brings the branches back, and cleanup sweeps delete unmerged ones (anthropics/claude-code#38287), so plan the return:

- Scope briefs disjoint; overlapping files means the work was not parallel.
- On return, rebase onto the current base and fast-forward, then rebase the next onto the moved base.
- Merge only a branch someone else already holds; squash only where commits do not stand alone.
- Remove the worktree and delete its branch (`git branch -d`) in the same step as integration.
- Keep a long-running effort on its own branch.
- Reconciliation goes out like other work, carrying what each branch was for.

## The brief

Each brief stands alone: the agent has no memory of this conversation.
State what is under test or construction, what counts as done, constraints it cannot infer, and what was already tried and failed (or that nothing was).
Name a skill for skill-governed work; do not open its `SKILL.md` first.
Implementation briefs declare the review outcome: `independent-code-review` only for final delivery of a completed behaviour-changing feature, otherwise state no review.
Require a distilled return -- findings and paths, not raw output -- with what it ran marked apart from what it read.
A young project needs longer briefs.
A fact entered in a second brief earns a line in `AGENTS.md`; propose it and wait for the user to take it.

Check an agent holds `Agent` before briefing it to fan out; an explicit `tools:` list grants only what it names.
Keep chains short: a grandchild's results are unreliable once its parent has finished.
