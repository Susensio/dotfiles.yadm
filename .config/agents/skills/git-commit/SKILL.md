---
name: git-commit
description: Stages and commits pending work as atomic commits — one concern each, staged by explicit path, in this repo's existing message style. Use when asked to commit changes here.
---

# Git Commit Protocol

1. Inspect state: `git status` and `git diff --stat`.
2. **No-op guard:** nothing changed, or only scratch files under a job tmp dir — abort and say so rather than producing an empty commit.
3. **Atomicity:** changes spanning unrelated concerns get split, one commit per concern, each buildable and revertable on its own — a split that leaves an intermediate commit not building is not atomic.
   Repeat steps 4-7 per concern.
   Landing in the same turn is not a reason to bundle.

   Over-splitting is the commoner failure, and atomic tracks the concern, not the edit count.
   An edit that only makes sense in light of the last one is the same concern: a follow-up trim, a correction to a line just written, the rule that codifies the fix just made.
   Any one of these means it belongs to the commit before it — the message would read as *continue*, *also* or *fix the previous*; reverting it alone would leave the tree incoherent; it only touches lines that commit just wrote.
   While that commit is unpushed, amend it.
   A second commit is the wrong shape, not a smaller one.

   Never record an experiment and its retraction.
   A change taking back something committed earlier in the same unpushed run gets amended or dropped, never stacked on top; two commits that cancel are noise in the permanent record.
   Whatever the detour taught still has to land — in the file that governs it, or in an ADR — before the commits carrying it go.
4. **Selective staging:** stage by explicit path.
   Never `git add .` — a working tree routinely carries unrelated in-flight edits.
5. **Message:** read `git log` first and match the existing history — its casing, its mood, and whether it uses conventional-commit prefixes.
   The repo's own record is authoritative; do not impose a convention it does not already follow.
   **Fallback:** a repo with no history, or too little to read a convention from, gets conventional commits — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
6. **Decision check:** if a concern reverses a prior decision, or adopts a constraint for a non-obvious reason, say so before committing — it may want an ADR.
   A commit is where a decision lands, and the only moment it is still obvious that one was made.
7. Commit with `git commit -m "<message>"`.
