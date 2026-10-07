# Agent harnesses

The global userspace harnesses live under `~/.config/claude/` and `~/.config/pi/agent/`; Codex reuses Pi's shared guidance and skills.
This document explains the boundaries and design choices common to them, then the Claude-specific setup that needs operational explanation.
For Pi's tracked files and operating notes see [`pi/README.md`](../pi/README.md).
These are user-global configurations, not project-local harnesses such as a repository's `.claude/` directory.

## Shared approach

Keep instructions that every session needs short; load conditional procedures through skills and use subagents when an independent execution context pays for itself.
The main session owns decisions, sequencing, integration, and final correctness.
Agents provide execution boundaries, skills provide on-demand knowledge, and extensions or hooks handle behavior prose cannot enforce reliably.
The live configuration and skills, not this document, govern which agents, models, tools, and packages run today.

Pi uses the ordinary session as its sole main entry point and keeps its subagents as independent task containers.
Claude also offers a dedicated `leader` entry point for project orchestration; its role and hooks differ from Pi's, so they are not mirrored automatically.
Codex shares Pi's global working-style instructions via `~/.config/codex/AGENTS.md` → `~/.config/pi/agent/AGENTS.md`, and discovers shared skills through `~/.config/codex/skills/shared` → `~/.config/pi/agent/skills/`.
Codex keeps its own agent definitions, permissions, and runtime settings; the symlinks share guidance, not behavior or model configuration.

Some Claude and Pi skills are symlinked when one harness-neutral procedure serves both; others have the same name but separate implementations because their workflows and context budgets differ.
A change to an independently maintained skill should not be copied to the other harness merely for symmetry.

## Claude Code

Claude's configuration applies across projects for this user.
It lives under `~/.config/claude/`, pointed at by `CLAUDE_CONFIG_DIR`.
That tree is the only source of truth: anything elsewhere that reads as harness config is a compiled copy, so edit it here.
Keep the hand-maintained config here as real files.
`CLAUDE_CONFIG_DIR` also puts credentials, session transcripts and plugins in this directory; `yadm/exclude` and `claude/.gitignore` keep those out of version control.

Hooks and statuslines in `settings.json` use `$CLAUDE_CONFIG_DIR` and survive a directory move.
The write paths under `sandbox.filesystem.allowWrite` are literal; update them when moving the directory so the new location stays writable.
A stale path can silently deny writes.

Root commands go through `pkexec`, behind an ask in the agent's pane: `Bash(pkexec *)` is a `permissions.ask` rule, so Claude asks even in auto mode, and polkit's fingerprint dialog opens only after you answer ([ADR-0071](adr/0071-ask-before-pkexec.md)).
The sandbox strips setuid, so `claude/CLAUDE.md` has Claude run pkexec unsandboxed from the first call; `sandbox.excludedCommands` cannot do it, as Claude Code never lets it cover privilege wrappers (`sudo`, `su`, `doas`, `pkexec`, `runuser`, `chroot`).

## Two entry points

**`claude`** — the default session, on the account's default model; `settings.json` pins none.
Ad-hoc, no fixed role, does whatever the prompt asks.
This is what runs when nothing else is specified — including background jobs.

**`claude --agent leader`** — a project's main agent, on `opus`.
`leader` doesn't do the work itself: it decides what happens next, dispatches tasks to subagents, and reconciles what comes back.
It owns the project's record — decisions, backlog, notes — in whatever form that project keeps them, instead of the diff; the roadmap is the user's, and it reads that without editing.
It's only ever a top-level entry point, never something a subagent spawns.

Both are "main-thread" modes — the difference is whether the session orchestrates (`leader`) or just acts (`claude`).

## The subagents

`leader` (and `claude`, when it chooses to delegate) dispatches to five first-party subagents, each pinned to one job and one model -- a plugin can add its own, see Plugins below:

| Agent | Job | Model |
|---|---|---|
| `developer` | Implements one scoped change, verifies it, commits it | sonnet |
| `tester` | Runs one isolated check against something running, returns pass/fail | sonnet |
| `auditor` | Judges work it didn't produce against a named standard — read-only | opus |
| `explorer` | Searches a large surface (files, logs, the web), returns a cited answer | haiku |
| `documenter` | Propagates already-settled wording across files | haiku |

Each is briefed standalone — none of them remember the conversation that spawned them.
The `delegation` skill has the full picture of when handing off pays for itself.

## Plugins

`claude plugin` installs third-party additions under `claude/plugins/`, outside the hand-maintained tree above and untracked — a plugin owns its own agents and skill triggers, and updates independently of this repo.

The `codex` plugin (`codex@openai-codex`) adds `codex-rescue`, an agent Claude reaches for on its own judgement — its description says to use it proactively when Claude is stuck or a task should go to Codex/GPT-5.x instead, the same shape of trigger the five first-party agents above carry.
It runs against the user's Codex/ChatGPT quota, not Claude's.
`/codex:review`, `/codex:adversarial-review`, `/codex:cancel`, `/codex:result`, `/codex:status` and `/codex:transfer` are `disable-model-invocation: true` — typed only, unreachable by any agent's own judgement; `/codex:setup` and `/codex:rescue` are not.
Run `/codex:setup` once per machine to authenticate.
The plugin also registers `SessionStart`/`SessionEnd` hooks of its own (job bookkeeping, not in the table below) and an opt-in `Stop` review gate, off until `/codex:setup --enable-review-gate` — left off deliberately, since `Stop` fires at the end of every turn, not at session end.

`independent-code-review` (a skill, not a plugin command) reaches the same native reviewer without the gated command, by reading `review.md`'s current invocation and running the equivalent directly.
It is opt-in: it runs only when a brief explicitly requests it for a completed feature that changes behaviour, once per feature, never per commit, task, doc change or chore.

## Skills

Skills are knowledge loaded only when it's relevant, instead of sitting in context every turn.
Some are user-invocable (`/adr`, `/git-commit`, `/grow-project-docs`...), others fire only when an agent's own judgement calls for them (`delegation`, `project-docs`, `harness-design`).
`claude/skills/` has the full list; each `SKILL.md` says in its own description when to reach for it.
Four of them (`report-issue`, `tmux-config`, `tmux-testing`, `tui-testing`) are shared with the pi harness by symlink from its agent skills directory -- the copies stay canonical here, and the skills stay harness-neutral so one file serves both.
Six more share names (`adr`, `coding`, `delegation`, `git-commit`, `harness-design`, `project-docs`) but are deliberately independent: the pi harness is a slim variant of this one, and where a skill's full depth exceeds pi's context budget pi keeps its own terser rewrite instead of the symlink.
Neither copy is canonical for the other; editing one is not an edit to the other, and an edit should not be propagated unless both harnesses actually need it.

## Rules

`claude/rules/*.md` are standards scoped to a file path or extension (`fish.md`, `python.md`, `markdown.md`, `harness.md`).
They load automatically on a matching file's **read**, natively — no invocation needed.
They also load on a matching file's **write**\*, because a file created fresh is never read first: `rules-on-write.py` (below) backfills that gap, after the fact, and asks the model to rewrite the file if the rule would have changed it.

\* This write-time load is powered by a custom hook in this harness, not a native Claude Code feature.

## Hooks

Hooks cover what prose cannot enforce reliably or the runtime does not deliver on its own.
Each script's docstring holds why it exists and what it was probed against; this table is only the map.

| Event | Script | Does |
|---|---|---|
| `SessionStart` (startup, clear) | `skills-on-launch.py` | injects the `skills:` a `--agent` launch declares, which the runtime loads only for spawned subagents |
| `SessionStart` | `herdr-agent-state.sh` | reports the session to herdr's pane state; written and overwritten by herdr's integration installer, so its absolute path is herdr's, not `$CLAUDE_CONFIG_DIR` |
| `PreToolUse:Bash` | `prefer-rich-cli.py` | nudges toward `rg`/`fd`/`jq` once per binary per agent; never blocks |
| `PreToolUse:Write\|Edit` | `rules-on-write.py` | injects path-scoped rules for a file being written, which natively load only on read |
| `PreToolUse:Write\|Edit` | `not-your-repo.py` | nudges before a new record file is created in a repository you do not own; never blocks |
| `PostToolUse:Write\|Edit` | `autoformat.py` | formats what was just written and says when the on-disk copy changed |
| `PostToolUse` and `PostToolUseFailure` (Bash and file tools) | `sandbox-noise.py` | names any path a call touched that is the sandbox's `/dev/null` mount, so it is neither chased nor reported |

The nudging hooks keep quiet after their first word by stamping a marker under `$TMPDIR/claude-hook-nudge`.

For how a new piece of harness content should be slotted in (agent vs. skill vs. rule vs. `CLAUDE.md` vs. a doc like this one), see the `harness-design` skill — it's the doctrine this whole layout follows.
