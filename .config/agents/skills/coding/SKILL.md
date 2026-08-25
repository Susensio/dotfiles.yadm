---
name: coding
user-invocable: false
description: How code is written, read and commented here — what to check before adding any, the shape it takes once written, how a comment earns its place, the check-and-fix loop that lands a change green, how much verification a change deserves, and how to work through a failure instead of guessing at it. Use proactively whenever code is involved at all — reading it, writing it, editing it, reviewing a diff, or when a test, lint or type check fails.
---

# Coding

## Before writing anything

Check, in order:

1. Can this be deleted instead, or does the codebase already solve it somewhere else?
   Search before you write.
2. Does a well-maintained library solve it more legibly than hand-rolling, or than a clunkier stdlib API?
3. Only once 1 and 2 are exhausted, write new code.

Build the minimal thing that satisfies the requirement.
No speculative abstractions, no unused helpers, no packages beyond what step 2 justified.

An abstraction earns its place from what varies between its callers, so check what actually varies.
A parameter, field or return value that is identical at every call site is carrying nothing -- delete it and inline what it held.
A function whose body only calls two others is not a layer.
Where a caller works around the interface -- a lookup table to reach it, a value smuggled through a slot meant for something else -- the interface is wrong, not the caller.

## Shape

Prefer the **explicit**: named arguments, declared types, data that flows through parameters rather than through module state.
A hidden path costs nothing to write and everything to trace, and the reader who has to find it is usually you, later, with less context than you have now.

Keep it **flat**.
Guard clauses and early exits over an else branch running to the bottom of the function.
Deep nesting reads as conditions that compound, and they usually do not -- most of them are unrelated checks stacked by whoever added them last.

Never swallow an error.
A bare `except: pass` converts a failure into wrong output that arrives later, somewhere else, without the traceback that explained it.
Catch what you can name, handle that, and let the rest surface.

## Verify against reality, not against the diff

Pipeline and algorithmic logic gets run against real sample data before it counts as done.
A change that only looks right is not finished, it is untested.

## Land it green

Implement, then run the project's checks cheapest first -- formatter and linter, then type checker, then tests.
Fix what each reports before running the next: a type error read through a wall of lint noise costs more than the run it would have saved.
Repeat the cycle until every check passes on the same pass.
A change is done at the first clean run across all of them, not at the last edit.

Where the project declares no check, say what went unverified rather than calling it done.

## When something fails

Work through these in order.
Do not skip to a fix you cannot yet explain.

1. **Reproduce.**
   Confirm the failure is real and repeatable, and find the smallest case that triggers it.
2. **Root cause.**
   Read the actual code path, stack trace or log, and state why it fails as a claim that could be proven wrong.
   Not a guess.
3. **Fix.**
   Patch the mechanism identified in step 2 and nothing else.
   Never pattern-match a plausible-looking change, and never weaken a test's assertion in place of fixing what it caught.
4. **Verify.**
   Rerun the specific failure, then the full suite.

If you cannot complete step 2, go outward before iterating.
Confusing behaviour in mature third-party software has usually been reported already: read the project's issue tracker first, then the wider web.
Infer the resolution from the comments and the close reason -- some maintainers do not merge through GitHub, so a missing linked PR does not mean unfixed -- and check both that the issue applies to the version in use and that the fix shipped in it.
Still without a root cause after that, say so and ask a specific blocking question rather than iterating blindly.

Once two attempts at the same failure have failed, stop and hand the code and the failure to `auditor` instead of trying a third variant.
The third variant is where a plausible-looking change lands on top of an unexplained one, and a judge that did not write the code is the cheapest way out of a loop you are inside.

## Comments

Comment sparingly -- for the quirk that will annoy future-self, not for what the code already says.
A comment earns its place only when something is genuinely non-obvious: a hidden constraint, a workaround for a specific bug.
No header blocks explaining what a file does -- let names carry that.
Fragments over full sentences; drop articles and pronouns if meaning survives.

Word them flat, declarative, impersonal:

- One idea per comment.
  If it needs an "and" or a colon to fit two, write two.
- Keep the why, drop the wrapper around it.
  "tmux's own dispatch handles compound bindings; re-parsing the command text would not" -- not "which is what saves this from...".
- No hedge words: "really", "already", "actually", "basically", "essentially".
- Docstrings lead with the shape of the return value, not "this function returns...".
- `BUG:` plus one bare sentence for a known defect.

## Scale the checking to the change

Ask what the change could plausibly break, check exactly that, and stop.
An edit that cannot alter behaviour -- a comment, a docstring, whitespace -- is verified by reading the diff.
Reserve the full suite, the throwaway server and the before/after harness for changes that genuinely alter behaviour.
