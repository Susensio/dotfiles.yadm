# General preferences

- When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.
- Confusing behavior in mature software I didn't write: read the project's issue tracker before trial-and-error.
  Infer the resolution from comments and close reason -- some maintainers don't merge via GitHub, so a missing linked PR doesn't mean unfixed.
  Check both that the issue applies to the version in use and that the fix shipped there.
- Shelling out via `Bash`, prefer the richer CLI where installed -- `rg`, `fd`, `jq`, `delta`/`bat` -- and fall back silently to the POSIX default when absent (`command -v`).
  Applies to every subagent.
  Not to built-in `Grep`/`Glob`, already on fast backends.
- `Bash` commands take absolute paths, never a `cd X && ...` prefix.
  Leaving the working directory in a compound command defeats sandbox auto-approval and forces a permission prompt.
  Applies to every subagent.
- Commit atomically, one concern per commit, each revertable on its own.
  Protocol in the `git-commit` skill.
- Remembering something: it goes where the project's own harness already keeps that kind of fact -- a CLAUDE.md, a skill.
  Agent memory only when it fits nowhere else.
  One place, never both.
- Markdown prose breaks by sentence, one per line, never hard wrapped to a column.
  Frontmatter, fenced code, tables and headings stay verbatim.
- Delegate on your own judgement, without waiting for me to ask.
  This overrides the `Agent` tool's own instruction to spawn only on my explicit word.
  Which agent, whether the handoff pays and which model are the `delegation` skill's -- read it before spawning.
