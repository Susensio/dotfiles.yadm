---
name: agy
description: Runs work on `agy`, a non-Claude agent CLI on a separate quota, when Claude's own is spent. Use when a rate limit blocks the work and a checked partial answer beats none, when an investigation must resume across sessions days later, and whenever the user names agy. It substitutes for Claude rather than checking Claude's work — measured against a Claude auditor on the same code, it raised no high-severity finding.
---

# agy

`agy` is Google's Antigravity CLI, signed in on a quota that is not Claude's.
That separate quota is the reason to reach for it.
The different model family is not: it was measured and it did not pay.

## Reach it through `call`

`~/.config/claude/skills/agy/call` wraps `agy` in `bwrap`.
The workspace is read-only, everything outside it is read-only or absent, and credentials and settings are read-only, so a run cannot alter the tree it reads or grant itself permissions.
Pass `--write` as the first argument for the rare run that must edit.

Bare `agy` is on `PATH` and soft-denies its command tool headless, and its own error message names `--dangerously-skip-permissions` as the way out.
`call` already sets that flag, safely, because the sandbox is the boundary.

## What it is worth

Measured once, against a Claude `auditor` reviewing the same 4,500-line Python project: 87.5% of agy's findings survived checking, but it raised no high-severity defect, cost 2.2× the wall-clock, and closed one run with a confident all-clear on code that was broken.
Two Claude auditors on that same tree diverged from each other more than agy added to either.

So it substitutes for Claude rather than supplementing it.

- **Claude's quota is spent.** A checked 87.5% beats no answer, and this is the case that recurs.
- **The work outlives the session.** `-c` reaches a conversation days later; an `explorer` dies with the session that spawned it.
- **What it is good at, a linter reaches cheaper.** Its findings clustered on unused symbols, unreachable branches and dead config. `ruff` and `ty` get there faster and for free.

## Running it

```bash
cd /the/repo
~/.config/claude/skills/agy/call --model gemini-3.1-pro-high --effort high -p \
  "Review the working-tree diff against the standard in <path>. \
   Report findings only, as file:line plus one sentence each. \
   If nothing is wrong, say so plainly."
```

- **`$PWD` is the whole world it sees writable**, and `--chdir` puts it there. `$HOME` is blank inside the sandbox, so a standard has to live either in the workspace or in the compiled harness.
- **It already knows the conventions.** `claude2agy` compiles `~/.config/claude/` into `~/.gemini/config/` — `AGENTS.md`, the rules and the skills — and that directory is bound read-only. Verified present; agy does not always load them, so say which standard you want applied rather than assuming it arrives.
- **`--agent <name>` runs your own definition there.** claude2agy compiles the agents too, so a substitute run can carry the same contract and report shape as the Claude one. `agy agents` lists what is available.
- **Model choice moved nothing.** `gemini-3.1-pro-high` performed worse than the Flash default on the one comparison there is, so run-to-run variance dominates; do not pay for the larger tier expecting a better answer.
- **`--output-format json` with `--json-schema`** bounds the return to a shape you choose, which is the one thing an `explorer` report cannot promise.
- **`-c` resumes** the last sandboxed conversation. Those live in `$XDG_STATE_HOME/agy-sandbox`, apart from the user's interactive agy history, and persist across Claude sessions.

## What comes back is a lead

A finding is a candidate to check against the artifact, and it is worth checking even when it turns out wrong.
A clean report proves nothing at all: one measured run called a tree perfect while a documented flag was broken and its test suite was red.
Report which findings survived checking, and say that agy raised them.
