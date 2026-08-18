# General preferences

- When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.
- Before a debugging rabbit hole on confusing behavior in mature software I didn't write, check the project's issue tracker first instead of pure trial-and-error -- it has often already been explained, sometimes by a maintainer. Infer the resolution from the comments and close reason; some maintainers don't merge via GitHub, so a missing linked PR doesn't mean unfixed. Check which version the issue applies to and whether the fix shipped.
- When shelling out via `Bash`, prefer faster/richer CLI tools over POSIX defaults where installed: `rg` over `grep`, `fd` over `find`, `jq` over ad hoc JSON parsing, `delta`/`bat` for diff or file preview. Applies to you and every subagent you delegate to.
  - Check with `command -v <tool>` if unsure whether one is present; fall back silently to the POSIX default rather than failing a task over a missing convenience tool.
  - Doesn't apply to the built-in `Grep`/`Glob` tools — those already run on fast backends.
- In fish, prefer `if`/`end` blocks over `and`/`or` chaining for control flow.
- Commit atomically: one concern per commit, each buildable and revertable on its own. If a turn's changes span multiple unrelated concerns, split into separate commits rather than bundling them because they landed in the same turn.
- When I ask you to remember something, first work out where it belongs. If the project has its own harness — a CLAUDE.md/AGENTS.md, a skill, or similar — and the info fits there, put it there. Only fall back to the agent memory directory when it fits nowhere in the project's own files. Record it in one place; don't duplicate it across both.
