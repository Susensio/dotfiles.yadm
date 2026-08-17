---
name: coding
user-invocable: false
description: How to write and change code here — what to check before adding any, and how to work through a failure instead of guessing at it. Use before writing or modifying code, and whenever a test, lint or type check fails.
---

# Coding

## Before writing anything

Check, in order:

1. Can this be deleted instead, or does the codebase already solve it somewhere
   else? Search before you write.
2. Does a well-maintained library solve it more legibly than hand-rolling, or
   than a clunkier stdlib API?
3. Only once 1 and 2 are exhausted, write new code.

Build the minimal thing that satisfies the requirement. No speculative
abstractions, no unused helpers, no packages beyond what step 2 justified.

## Verify against reality, not against the diff

Pipeline and algorithmic logic gets run against real sample data before it counts
as done. A change that only looks right is not finished, it is untested.

## When something fails

Work through these in order. Do not skip to a fix you cannot yet explain.

1. **Reproduce.** Confirm the failure is real and repeatable, and find the
   smallest case that triggers it.
2. **Root cause.** Read the actual code path, stack trace or log, and state why
   it fails as a claim that could be proven wrong. Not a guess.
3. **Fix.** Patch the mechanism identified in step 2 and nothing else. Never
   pattern-match a plausible-looking change, and never weaken a test's assertion
   in place of fixing what it caught.
4. **Verify.** Rerun the specific failure, then the full suite.

If you cannot complete step 2, say so and ask a specific blocking question rather
than iterating blindly.

## Scale the checking to the change

Ask what the change could plausibly break, check exactly that, and stop. An edit
that cannot alter behaviour -- a comment, a docstring, whitespace -- is verified
by reading the diff. Reserve the full suite, the throwaway server and the
before/after harness for changes that genuinely alter behaviour.
