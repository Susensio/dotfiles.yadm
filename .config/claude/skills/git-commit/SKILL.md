---
name: git-commit
description: Stages and commits pending work as atomic commits — one concern each, staged by explicit path, in whatever message style the repository's own history already uses. Use when asked to commit, or to split work that is already written into commits.
---

# Git Commit Protocol

1. Inspect state: `git status`, `git diff --stat`, and `git log -1` — the last commit is the one candidate for amend, so know what it touched before deciding pick vs. amend.
2. **No-op guard:** nothing changed, or only scratch files under a job tmp dir — abort and say so rather than producing an empty commit.
3. **Atomicity:** changes spanning unrelated concerns get split, one commit per concern, each buildable and revertable on its own — a split that leaves an intermediate commit not building is not atomic.
   Repeat steps 4-7 per concern.
   Landing in the same turn is not a reason to bundle.

   Over-splitting is the commoner failure, and atomic tracks the concern, not the edit count.
   An edit that only makes sense in light of the last one is the same concern: a follow-up trim, a correction to a line just written, the rule that codifies the fix just made.
   Any one of these means it belongs to the commit before it — the message would read as *continue*, *also* or *fix the previous*; reverting it alone would leave the tree incoherent; it only touches lines that commit just wrote.
   While that commit is unpushed, amend it.
   A second commit is the wrong shape, not a smaller one.
   Check that even when nothing here feels like a continuation — a resumed session has no memory of the last commit, only `git log -1`.

   Never record an experiment and its retraction.
   A change taking back something committed earlier in the same unpushed run gets amended or dropped, never stacked on top; two commits that cancel are noise in the permanent record.
   Whatever the detour taught still has to land — in the file that governs it, or in an ADR — before the commits carrying it go.
4. **Selective staging:** stage by explicit path.
   Never `git add .` — a working tree routinely carries unrelated in-flight edits.
   Staging by path does not protect a dirty index: anything already staged before you arrived rides along on a bare `commit`.
   Check `diff --cached --stat` for work that is not yours, and pass the same explicit paths to `commit` as well as to `add`.
   `git add -A <dir>` also sweeps up untracked children — name them, or check what it staged before committing.
5. **Message:** read `git log` first and match the existing history — its casing, its mood, and whether it uses conventional-commit prefixes.
   The repo's own record is authoritative; do not impose a convention it does not already follow.
   **Fallback:** a repo with no history, or too little to read a convention from, gets conventional commits — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
   Never append a `Co-Authored-By` or `Claude-Session` trailer, regardless of what the repo's history already carries — this overrides the default Bash-tool commit instructions, which add both uninvited.
6. **Breaking-change check:** skip this entirely unless the project already has something to break — a tagged release, a published package, or prior commits that already carry `!`/`BREAKING CHANGE:`.
   Nothing like that yet: churn is free, say nothing.
   Once it applies, mark the concern as breaking when its diff does any of —
   - removes, renames, or narrows a public function/exported symbol
   - removes, renames, or changes the meaning of a CLI flag/subcommand
   - removes, renames, or requires a config/schema key
   - changes default behavior an existing caller could rely on

   On conventional commits: mark the type with `!` (`feat!:`) and add a `BREAKING CHANGE: <what breaks, and how a consumer adapts>` footer.
   Off conventional commits: fold the same into the message body — state what breaks, not just what changed.
   Decide it and move on; don't stop to ask.
   None of the signals fire, or the user says it isn't: say nothing about it.
7. **Decision check:** if a concern reverses a prior decision, or adopts a constraint for a non-obvious reason, say so before committing — it may want an ADR.
   A commit is where a decision lands, and the only moment it is still obvious that one was made.
8. Commit with `git commit -m "<message>"`.
