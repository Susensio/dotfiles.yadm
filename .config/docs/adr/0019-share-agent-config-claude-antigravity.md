# ADR-0019: Share agent configuration between Claude Code and Antigravity

Status: Superseded by [ADR-0020](0020-collapse-harness-to-claude-code.md)
Date: 2026-08-07

## Context

Running both Antigravity and Claude Code against the same tmux config work.
Each harness reads its own instruction file (`AGENTS.md` vs `CLAUDE.md`) and its own skill directory.
Keeping two copies of the same tmux rules and the same tmux-helper skill in sync by hand is exactly the kind of drift that produces a stale instruction one agent follows and the other doesn't.

## Decision

`.agents/` becomes the single source of truth: `AGENTS.md` plus the `tmux_helper` skill live there, and Claude Code reads the same files through symlinks — `CLAUDE.md` -> `.agents/AGENTS.md`, `.claude/skills/tmux_helper` -> the shared skill directory.
A change is made once, in `.agents/`, and both harnesses see it.

## Consequences

One edit updates both agents; no more parallel-maintenance drift between `AGENTS.md` and `CLAUDE.md`, or between two copies of the tmux-helper skill.

Costs: symlink indirection — reading `CLAUDE.md` in isolation no longer shows the content, you have to know to follow the link.
And the two harnesses don't share every convention (directory naming, skill-name rules) — those differences have to be reconciled into one shared tree rather than left to diverge per-harness.

