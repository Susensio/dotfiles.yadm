# ADR-0024: Track global agent config in .config/agents and symlink it into ~/.claude

Status: Superseded by [ADR-0036](0036-claude-config-dir-over-binds.md)
Date: 2026-08-16

## Context

Claude Code reads user-level agents, skills and commands from `~/.claude/`.
That directory cannot be tracked: it is outside XDG, and the handful of hand-written files sit among runtime state — sessions, history, credentials, caches, job and telemetry dirs.
yadm's exclude allowlist covers `~/.config` and a few siblings, so everything under `~/.claude/` is invisible to the repo and lost on a new machine.

ADR-0020 removed symlink indirection from the agent harness, on the grounds that it bought provider-agnosticism nobody was using.

## Decision

The hand-written global harness lives in `~/.config/agents/` — `agents/`, `skills/`, `commands/` — whitelisted in `yadm/exclude` as `!/.config/agents/`, and `~/.claude/{agents,skills,commands}` are symlinks into it.
`~/.claude/` itself stays untracked.

## Consequences

Global agents, skills and commands are version controlled and portable, and `~/.claude/` keeps holding only state that is worthless off this machine.

Cost: symlink indirection returns, the thing ADR-0020 deleted.
The reversal is partial — one vendor and no `AGENTS.md` still hold; what comes back is the link, for a different reason: not sharing config between harnesses, but hoisting files out of a directory that cannot be tracked.

The links are made by hand today, so a fresh clone has none until a `yadm/bootstrap.d` script creates them.
Empty subdirectories do not survive a clone either — each needs content before the mapping is complete.

`agents/agents/` reads oddly.
Accepted so the directory names match what Claude Code expects one-to-one, keeping the symlinks a straight mapping rather than a renaming to remember.

Project-scoped harness under `.config/.claude/` is a separate question, still untracked; it needs a longer negation chain in `yadm/exclude` because git cannot re-include a child of an excluded directory.
