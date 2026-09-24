---
name: project-docs
description: Routes project information to existing or standard repository documents. Use before creating, moving, or recording project documentation.
---

# Project documents

Project facts belong in the repository, not agent memory.
Find their existing home before inventing one.

## Follow the repository

1. Inspect the nearest repository guidance, `README`, contribution docs, documentation tree, and linked tracker.
2. Determine whose convention governs the repository.
   In an upstream or other-owned repository, report findings instead of creating records or conventions unless asked to edit them.
3. Match the established location and format.
   When two homes fit, follow the one most recently used for the same kind of information.
4. Read a document before changing it.

## Grow this user's projects by overflow

When the user's own repository has no established home, use these defaults.
They are consistent destinations, not a schema to create up front.
A document is earned only when its information no longer fits its current home or the triggering state actually exists.

| Information | Default location | Earned when |
| --- | --- | --- |
| Project identity and usage | `README.md` | someone needs to use the project without changing it |
| Required behavior | `docs/SPEC.md` | the README cannot contain the requirements clearly |
| Ordered milestones | `docs/ROADMAP.md` | the README's roadmap or TODO has outgrown it |
| Open work nobody is doing | `docs/BACKLOG.md` | the README's TODO has outgrown it |
| Committed work left unfinished | `docs/STATE.md` | work or an accepted decision must survive a session boundary |
| Durable architectural decisions | `docs/adr/` | the `adr` skill says the decision merits a record |
| Human-operated procedures | a focused file under `docs/` | a person will perform the procedure too |
| Throwaway working material | `.scratch/` | the first temporary repository-local file is needed |

The repository root holds entry points; overflow belongs under `docs/`.
Do not create empty process files.
Treat roadmaps as user-owned unless asked to change them.
Keep `docs/STATE.md` current rather than append-only, and remove it when the tracked work finishes.
Ignore `.scratch/` before using it and remove its contents when the work lands.
Use the `adr` skill for decisions rather than treating ADRs as ordinary overflow.

Read [references/files.md](references/files.md) before creating or reorganizing one of these standard documents.
