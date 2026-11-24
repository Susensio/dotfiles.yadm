---
name: coding
user-invocable: false
description: Use whenever code is involved: reading, writing, editing, reviewing a diff, or a failing test, lint or type check. Covers what to check first, shape, comments, the check loop, and debugging.
---

# Coding

## Before writing anything

When the brief requests `independent-code-review`, capture `git rev-parse HEAD` before the first edit; the pre-change ref is not cleanly recoverable once in-flight commits mix in.

Check in order:

1. Can this be deleted, or does the codebase already solve it? Search before you write.
2. Does a well-maintained library solve it more legibly than hand-rolling?
3. Only then write new code.

Build the minimal thing that satisfies the requirement: no speculative abstractions, no unused helpers.
A parameter, field or return value identical at every call site carries nothing -- inline it.
Where a caller works around an interface (a lookup table to reach it, a value smuggled through the wrong slot), the interface is wrong.

## Shape

- Explicit: named arguments, declared types, data through parameters rather than module state.
- Flat: guard clauses and early exits over deep nesting.
- Never swallow an error. Catch what you can name, let the rest surface.

## Land it green

Run the project's checks cheapest first -- formatter and linter, then type checker, then tests -- fixing each before the next.
Done is the first clean run across all of them, not the last edit.
Pipeline and algorithmic logic runs against real sample data before it counts.
Scale checking to the change: a comment, docstring or whitespace edit is verified by reading the diff; reserve the full suite and throwaway servers for behavioural changes.
Where the project declares no check, say what went unverified.

Run `independent-code-review` only when the brief explicitly requests it for a completed behaviour-changing feature, once, after all its commits are present.
Give the reviewer the pre-change ref and require findings back verbatim.
Fix findings like linter output; say plainly where you disagree.
A disputed correctness finding goes to `/code-review`; a decision about the approach goes to `auditor`.

## When something fails

In order, never skipping to a fix you cannot explain:

1. **Reproduce** -- the smallest repeatable case.
2. **Root cause** -- read the code path, trace or log; state why it fails as a claim that could be proven wrong.
3. **Fix** -- the mechanism from step 2 only; never weaken an assertion in place of fixing what it caught.
4. **Verify** -- the specific failure, then the full suite.

Without a root cause, go outward: the project's issue tracker, then the wider web.
Read the resolution in comments and close reason, and check the fix applies to and shipped in the version in use.
Still stuck: say so and ask a specific blocking question.

After two failed attempts at the same failure, stop and hand code and failure to `auditor` rather than trying a third variant.

## Comments

Only for the non-obvious: a hidden constraint, a workaround for a specific bug.
No file header blocks.
Flat, declarative fragments, one idea each, no hedge words ("really", "already", "actually", "basically").
Docstrings lead with the shape of the return value.
`BUG:` plus one bare sentence marks a known defect.
