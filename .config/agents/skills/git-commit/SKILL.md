---
name: git-commit
description: Stages and commits pending work as atomic commits — one concern each, staged by explicit path, in this repo's existing message style. Use when asked to commit changes here.
---

# Git Commit Protocol

1. Inspect state: `git status` and `git diff --stat`.
2. **No-op guard:** nothing changed, or only scratch files under a job tmp dir — abort and say so rather than producing an empty commit.
3. **Atomicity:** changes spanning unrelated concerns get split, one commit per concern, each revertable on its own. Repeat steps 4-7 per concern. Landing in the same turn is not a reason to bundle.
4. **Selective staging:** stage by explicit path. Never `git add .` — a working tree routinely carries unrelated in-flight edits.
5. **Message:** read `git log` first and match the existing history — its casing, its mood, and whether it uses conventional-commit prefixes. The repo's own record is authoritative; do not impose a convention it does not already follow. **Fallback:** a repo with no history, or too little to read a convention from, gets conventional commits — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
6. **Decision check:** if a concern reverses a prior decision, or adopts a constraint for a non-obvious reason, say so before committing — it may want an ADR. A commit is where a decision lands, and the only moment it is still obvious that one was made.
7. Commit with `git commit -m "<message>"`.
