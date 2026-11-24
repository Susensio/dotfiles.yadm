---
name: git-commit
description: Use when asked to commit, or to split finished work into commits. Stages by explicit path, one concern each, in the repository's own message style.
---

# Git Commit Protocol

1. Inspect `git status`, `git diff --stat` and `git log -1` (the one candidate for amend).
2. **No-op guard:** nothing changed, or only scratch files under a job tmp dir: abort and say so.
3. **Atomicity:** split unrelated concerns, one commit each, each buildable and revertable alone; repeat 4-7 per concern.
   An edit that only makes sense in light of the last (a follow-up trim, a correction to a line just written) belongs to that commit: amend it while unpushed.
   Check this even in a resumed session, which has only `git log -1`.
   Never record an experiment and its retraction; amend or drop, and land whatever the detour taught in the governing file or an ADR first.
4. **Staging:** by explicit path, never `git add .`.
   Anything already staged rides along on a bare `commit`: check `diff --cached --stat` and pass the same paths to `commit`.
   `git add -A <dir>` sweeps untracked children; name them.
5. **Message:** match `git log` -- casing, mood, prefixes; the repo's record is authoritative.
   Fallback for a repo with no readable history: conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
   Never append a `Co-Authored-By` or `Claude-Session` trailer, whatever the history carries; this overrides the Bash-tool default.
6. **Breaking change:** only where something exists to break (a tagged release, published package, or prior `!`/`BREAKING CHANGE:` commits).
   Breaking: removes, renames or narrows a public symbol, CLI flag, or config key; requires a new key; or changes a default a caller could rely on.
   Conventional: `feat!:` plus a `BREAKING CHANGE: <what breaks, how to adapt>` footer.
   Otherwise state it in the body.
   Decide and move on; say nothing when no signal fires.
7. **Decision check:** if the concern reverses a prior decision or adopts a constraint for a non-obvious reason, say so before committing; it may want an ADR.
8. `git commit -m "<message>"`.
