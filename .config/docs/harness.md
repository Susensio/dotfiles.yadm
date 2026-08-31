# Claude Harness

This explains the global userspace Claude Code configuration, which applies across all projects for this user: the two ways to start a session, what each piece of `~/.config/claude/` does, and the hooks that quietly fix behaviour the model would otherwise get wrong.
Land here first if you're an agent picking up work in `~/.config/claude/`, or a human trying to understand what's running globally.
Note that this doc describes the global userspace harness, not a project-local harness (like `.claude/` in a specific repository).

All of it lives under `~/.config/claude/`, pointed at by `CLAUDE_CONFIG_DIR`.

## Two entry points

**`claude`** — the default session, on `sonnet`.
Ad-hoc, no fixed role, does whatever the prompt asks.
This is what runs when nothing else is specified — including background jobs.

**`claude --agent leader`** — a project's main agent, on `opus`.
`leader` doesn't do the work itself: it decides what happens next, dispatches tasks to subagents, and reconciles what comes back.
It owns the project's record — decisions, backlog, notes — in whatever form that project keeps them, instead of the diff; the plan is the user's, and it reads that without editing.
It's only ever a top-level entry point, never something a subagent spawns.

Both are "main-thread" modes — the difference is whether the session orchestrates (`leader`) or just acts (`claude`).

## The subagents

`leader` (and `claude`, when it chooses to delegate) dispatches to five subagents, each pinned to one job and one model:

| Agent | Job | Model |
|---|---|---|
| `developer` | Implements one scoped change, verifies it, commits it | sonnet |
| `tester` | Runs one isolated check against something running, returns pass/fail | sonnet |
| `auditor` | Judges work it didn't produce against a named standard — read-only | opus |
| `explorer` | Searches a large surface (files, logs, the web), returns a cited answer | haiku |
| `documenter` | Propagates already-settled wording across files | haiku |

Each is briefed standalone — none of them remember the conversation that spawned them.
The `delegation` skill has the full picture of when handing off pays for itself.

## Skills

Skills are knowledge loaded only when it's relevant, instead of sitting in context every turn.
Some are user-invocable (`/adr`, `/git-commit`, `/bootstrap-project-docs`...), others fire only when an agent's own judgement calls for them (`delegation`, `project-record`, `harness-design`).
`claude/skills/` has the full list; each `SKILL.md` says in its own description when to reach for it.

## Rules

`claude/rules/*.md` are standards scoped to a file path or extension (`fish.md`, `python.md`, `markdown.md`, `harness.md`).
They load automatically on a matching file's **read**, natively — no invocation needed.
They also load on a matching file's **write**\*, because a file created fresh is never read first: `rules-on-write.py` (below) backfills that gap, after the fact, and asks the model to rewrite the file if the rule would have changed it.

\* This write-time load is powered by a custom hook in this harness, not a native Claude Code feature.

## Hooks: fixing what the runtime doesn't

Hooks are the patches for gaps in how Claude Code natively delivers context.
Each one exists because something *should* happen automatically and doesn't, in one specific case:

- **`SessionStart` → `skills-on-launch.py`** — fires once, at startup only
  An agent's `skills:` frontmatter only auto-loads when it's *spawned* as a subagent — not when it's launched directly as the main thread (`claude --agent leader`).
  Without this, `leader` would start a session with none of the skills its own definition names.
  This hook reads the launched agent's declared skills and injects them at startup, so it reads as if they'd loaded normally.

- **`PreToolUse:Write` → `rules-on-write.py`** — fires once per rule, per agent
  Path-scoped rules (`claude/rules/*.md`) natively load when a file is *read*, not when it's freshly *written*.
  A file created from scratch would never see the rule governing how it should be written.
  This hook checks the rules directory against the file being written and injects any that match — too late to have shaped this write, so the message names the file and tells the model to rewrite it if the rule would have changed it.

- **`PreToolUse:Bash` → `prefer-rich-cli.py`** — fires once per binary, per agent
  Nudges toward `rg`/`fd`/`jq` over `grep -r`/`find -name`/hand-parsed JSON, when the richer tool is installed.
  Never blocks — it's a preference, not a rule, so `grep` inside a pipeline or `find -exec` still goes through untouched.

- **`PostToolUse:Write|Edit` → `autoformat.py`** — fires every time, no dedup
  Format-on-save for whatever was just touched (`ruff format`, `rustfmt`, `gofmt`, `biome`, project-pinned versions preferred over global installs).
  If formatting changes the file, the model is told its on-disk copy no longer matches what it wrote — otherwise the next edit builds on stale text and fails to apply.

`rules-on-write.py` and `prefer-rich-cli.py` get their once-per-agent quiet by stamping a marker under `$TMPDIR/claude-hook-nudge` the first time each speaks, so the same lesson doesn't repeat every call within a session.
`skills-on-launch.py` gets to once-only by construction — `SessionStart` fires on more than just startup (resume, clear, compact), and it acts on none of those.
`autoformat.py` skips dedup entirely: formatting is idempotent, so repeating it costs nothing.

## Where things live

```
claude/
├── CLAUDE.md       # always-loaded instructions (user-global)
├── settings.json   # hooks, permissions, model, statusline, sandbox
├── agents/         # leader + the five subagents above
├── skills/         # knowledge loaded on demand
├── rules/          # path-scoped standards
└── hooks/          # the four scripts above, plus utils.py
```

For how a new piece of harness content should be slotted in (agent vs. skill vs. rule vs. `CLAUDE.md` vs. a doc like this one), see the `harness-design` skill — it's the doctrine this whole layout follows.
