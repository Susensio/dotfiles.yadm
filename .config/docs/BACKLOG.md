# Backlog

Open work with no single line to mark: what is broken, what is owed, what has been thought about but not decided.
Not a task list for work in flight, and not a place for anything a `BUG:` or `TODO:` on the offending line already carries (ADR-0031).

- **med · agents** — An agent starting work in a project has no orientation step: it explores the file tree before reading anything that says what the project is or how it is run.

  A justfile or Makefile is a structured readme -- documentation about how the project is handled -- and it gets ignored, because nothing makes the agent look at it before it reaches for `.venv/bin/python`.

  Already done, and it covers one slice only:
  - `hooks/task-interface.py` injects `just --summary`, or Makefile targets from the git root, as `SessionStart` context.
  - `project-docs` routes "how the project is operated" to a justfile, and gates it on the same earned-not-adopted test as the other files.

  Probed, and it constrains the design: **`SessionStart` `additionalContext` does not reach a spawned subagent** (v2.1.238, two runs, control confirms the hook fires and the main thread receives it).
  So the recipe list reaches a bare session and never reaches `developer`, which is the agent that runs project commands.
  Candidate fixes, none chosen: a line in each agent body telling it to run `just --summary` itself; the caller carrying the recipe list in the brief, since the main agent already holds it; or a `PreToolUse` hook that fires per-tool rather than per-session.

  Open beyond the justfile: which artifacts count as orientation -- README, the external interface, what the project is for -- and in what order they are read.
  Whether `leader` needs a different orientation from a bare session.
  Whether any of it duplicates what a good `CLAUDE.md` already does, and what happens in a repo whose `CLAUDE.md` is bad.
