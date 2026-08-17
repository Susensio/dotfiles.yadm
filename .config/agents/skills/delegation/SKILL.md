---
name: delegation
description: Picks a subagent's model by task shape and decides whether the handoff pays for its cold start. Use before spawning any subagent, and when a task looks big enough to hand off but it is not obvious that it should be.
---

# Delegation

## Does this pay?

Delegation buys context isolation and pays a cold start: the subagent re-derives
everything from its prompt alone. Worth it for chunky self-contained work, a loss
for a few-line edit. Gate on size and self-containment, not on whether it is
"implementation".

## Pick the model by task shape, not task category

- `haiku` for enumeration and retrieval over a large surface -- grepping
  transcripts, trawling logs, inventorying a tree. Reliable at finding and
  listing, weak at deciding.
- `sonnet` for self-contained implementation with a clear spec and an obvious way
  to verify it.
- Delegate the legwork, never the call. Anything whose output is a judgment --
  ranking, trade-offs, what matters -- comes back to whoever is deciding.

Forks inherit the caller's model and ignore a `model` override. For cheap work,
spawn fresh rather than forking.

## Write the prompt to stand alone

The subagent has no memory of the calling conversation. State what is under test
or under construction, what counts as done, and any constraint it cannot infer.

Require a distilled return -- findings and file paths, not raw output. Keeping
the dump out of the caller's context is the point; a subagent that pastes its
transcript back has cost more than it saved.

## Nesting

A subagent can spawn its own subagents -- the Agent tool is in its toolset by
default. Results from a grandchild are unreliable once the parent has finished,
so keep a nested chain short and let each level return before the one above
completes.
