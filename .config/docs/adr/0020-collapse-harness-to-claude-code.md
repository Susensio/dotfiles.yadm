# ADR-0020: Collapse the agent harness to Claude Code only

Status: Accepted
Date: 2026-08-15
Supersedes: [ADR-0019](0019-share-agent-configuration-between-claude-code-and.md)

## Context

ADR-0019 built a provider-agnostic harness shared between Claude Code and
Antigravity via `.agents/` and symlinks, on the premise both would keep being
used. That premise no longer holds: "I'm tired of maintaining a provider
agnostic harness, i only use claude and i will remain doing so for the time
being. How can this simplify all my setup?" The abstraction — shared
`AGENTS.md` files, a symlinked skill directory, an `agents/global.md` symlink —
was being paid for continuously with no second consumer to justify it.

## Decision

Collapse the harness to Claude Code only. Three `AGENTS.md` files and the
`agents/global.md` symlink become plain `CLAUDE.md` files at `.config/`,
`.config/tmux/`, and `~/.claude/`. The shared `tmux_helper` skill becomes a
real directory, `.claude/skills/tmux-helper` (renamed with a hyphen — Claude
Code requires it), no longer a symlink target.

## Consequences

No more symlink indirection: `CLAUDE.md` files and the skill directory contain
their content directly. Nothing named `.agents` or `AGENTS.md` remains tracked
in the repo. Simpler to read, simpler to edit.

Cost: the setup is now coupled to one vendor. Adopting a second agent harness
later means re-splitting shared content back out — the ADR-0019 problem,
redone. Judged an acceptable future cost against paying the abstraction tax
today for a use case (Antigravity) that isn't happening.

