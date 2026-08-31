# ADR-0034: Onboard projects with a GLOBAL.md line instead of a session-start hook

Status: Accepted
Date: 2026-08-25

## Context

An agent entering a project had no orientation step: it explored the file tree before reading anything that says what the project is or how it is run.
The concrete failure named was `.venv/bin/pytest` where `just test` was declared, and the wider one was looping over a question the README already answered.

`hooks/task-interface.py` was the first attempt -- a `SessionStart` hook injecting `just --summary`, or Makefile targets from the git root, telling the agent to run project commands through that interface.
Probing it produced the finding that decided this: `SessionStart` `additionalContext` does not reach a spawned subagent, while a `PreToolUse` hook does fire on a subagent's own tool calls.
Both facts are recorded in the `harness-design` skill's runtime facts.

That split the design into two mechanisms, and examining each on its merits ended both.

A `PreToolUse` interception -- catch the wrong invocation as it is typed, name the recipe that covers it -- was the stronger half.
It reaches every agent, costs nothing when the agent is already right, and copies a pattern that works in `prefer-rich-cli.py`.

A `SessionStart` inventory of orientation documents was the weaker half, and the arguments against it apply to any version of it.
The agent can already see a README exists, because listing the directory is free and happens early; it loops because it did not think to read one, and a list of filenames does not fix not-thinking-to.
The cost is paid in every session in every repository, against a failure that is rare and cheap when it happens.
Where a project matters it has a `CLAUDE.md`, which does the same job better -- curated, specific, already loaded every turn.

Underneath both was that neither side had measured the failure rate.
The `.venv/bin/pytest` case was asserted from memory, never counted, and may be largely historical.
Two hooks and a parser across several ecosystems is a large bet on an unmeasured premise.

Rejected alongside the hooks: an `onboarding` skill holding the same guidance.
ADR-0030's exception applies exactly -- a skill loads only once the decision it governs is being taken, which is the same attention failure the content exists to correct.

## Decision

Onboarding is one bullet in `GLOBAL.md`: read what a project says about itself before exploring it, find where it declares how it is run and tested, drive it through that interface.
The bullet names `README`, `AGENTS.md` and `CONTRIBUTING` as what a project says about itself, and a justfile, `package.json` scripts, or the CI workflow as where the interface is declared -- the CI workflow being the fallback that covers a community repository declaring nothing else.

`hooks/task-interface.py` is deleted and its `SessionStart` registration removed from `settings.json`.
No `PreToolUse` onboarding hook is built.

`GLOBAL.md` is the slot because it is the only one that loads unconditionally in every agent, which is what R-in-time requires of content whose trigger must sit upstream of the choice it governs.
`just` is dropped from the richer-CLI bullet in the same edit: that list is about replacements for POSIX tools, and a task runner is a project interface, which the new bullet now owns.

`leader` gets more than this, and needs no change to get it -- it autoloads the `project-record` skill and follows a project's record already.

## Consequences

Enforcement is convention, and weaker than what was deleted.
A hook fires whether or not the agent was paying attention; a `GLOBAL.md` bullet is read and may be skipped, and it reaches subagents only because the whole `CLAUDE.md` hierarchy does.

Recipe names are no longer injected, so an agent spends a tool call discovering them instead of finding them already in context.
That is the trade taken: a lookup against the environment, which cannot go stale, in place of a cached copy paid for on every session start.

The premise stays unmeasured.
Nothing here counts how often the failure occurs, so if it turns out common, the evidence for rebuilding the `PreToolUse` half is a transcript scan that has not been run.
The reach facts survive that decision either way, which is why they are recorded apart from this ADR.

Orientation is one bullet for every session, and a bullet cannot be conditional on the repository.
A trivial session in a directory with no project pays a few tokens for guidance that will not fire, which is the same bargain the other `GLOBAL.md` bullets already make.
