---
name: coding
user-invocable: false
description: How code is written, read and commented here — what to check before adding any, how a comment earns its place, how much verification a change deserves, and how to work through a failure instead of guessing at it. Use proactively whenever code is involved at all: reading it, writing it, editing it, reviewing a diff, or when a test, lint or type check fails.
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

## Comments

Comment sparingly, like someone who'll be annoyed at future-self for not
understanding a quirk later. A comment earns its place only when something is
genuinely non-obvious: a hidden constraint, a workaround for a specific bug. No
header blocks explaining what a file does -- let names carry that. Favor terse
fragments over full sentences -- drop articles and pronouns if meaning survives.

Word them flat, declarative, impersonal:

- One idea per comment. If it needs an "and" or a colon to fit two, write two.
- Keep the why, drop the wrapper around it. "tmux's own dispatch handles compound
  bindings; re-parsing the command text would not" -- not "which is what saves
  this from...".
- No hedge words: "really", "already", "actually", "basically", "essentially".
- Docstrings lead with the shape of the return value, not "this function
  returns...".
- `BUG:` plus one bare sentence for a known defect.

## Scale the checking to the change

Ask what the change could plausibly break, check exactly that, and stop. An edit
that cannot alter behaviour -- a comment, a docstring, whitespace -- is verified
by reading the diff. Reserve the full suite, the throwaway server and the
before/after harness for changes that genuinely alter behaviour.
