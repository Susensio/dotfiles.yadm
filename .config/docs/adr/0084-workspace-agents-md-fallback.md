# ADR-0084: Name the dotfiles workspace instructions AGENTS.md now that Claude Code falls back to it, instead of keeping CLAUDE.md or symlinking both

Status: Accepted
Date: 2026-10-07
Supersedes in part: [ADR-0020](0020-collapse-harness-to-claude-code.md) — the workspace file's name; the user-tier `CLAUDE.md` stands

## Context

[ADR-0020](0020-collapse-harness-to-claude-code.md) renamed every `AGENTS.md` to `CLAUDE.md` when the harness collapsed to Claude Code.
Pi and Codex came back afterwards as Omarchy's agents, and the workspace instructions at `.config/` stayed Claude-only: Codex reads only `AGENTS.md`, so a Codex session in the dotfiles started without the yadm and records rules.
Claude Code 2.1.277 (2026-09-18) began reading `AGENTS.md` in a directory that has no `CLAUDE.md`, as the default of its project-instructions setting.

Weighed: keeping `CLAUDE.md`, which leaves Codex blind; a `CLAUDE.md` -> `AGENTS.md` symlink, the indirection [ADR-0019](0019-share-agent-config-claude-antigravity.md) paid for and ADR-0020 removed; and renaming the file to `AGENTS.md`.

## Decision

The dotfiles workspace instructions live in one plain file, `.config/AGENTS.md`, with no `CLAUDE.md` beside it.
The user-tier `claude/CLAUDE.md` and Pi's `pi/agent/AGENTS.md` were left as they were: they are deliberately different documents per the harness doc, and the fallback was confirmed only for project directories.

## Consequences

Claude, Pi and Codex read the same workspace rules from one file, with no symlink.

The fallback is silent in both directions.
A `CLAUDE.md` created beside `AGENTS.md` — by hand, by `/init`, or by a skill that writes "the project's `CLAUDE.md`" — makes Claude stop reading `AGENTS.md` without warning; add the line to `AGENTS.md` instead.
A Claude Code older than 2.1.277, a project-instructions setting other than the fallback default, or a Bedrock, Vertex or Foundry backend loads no workspace instructions at all.
