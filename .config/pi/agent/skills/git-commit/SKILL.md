---
name: git-commit
description: Creates atomic, verified Git commits that follow repository conventions. Use when asked to commit or split completed work into commits.
---

# Git commit

1. Inspect repository guidance, `git status`, staged and unstaged diffs, and recent commit history.
   If nothing relevant changed, stop rather than creating an empty commit.
2. Divide work by concern.
   Each commit must be coherent, buildable, and independently revertible.
   Amend an unpushed commit when a change only completes or corrects that same concern; do not preserve experiments and their retractions as separate commits.
3. Run the checks appropriate to each concern before committing it.
   Keep incomplete or failing work uncommitted.
4. Stage explicit paths and inspect the cached diff.
   Leave unrelated staged and unstaged work untouched; never rely on `git add .` in a dirty tree.
5. Match the repository's established commit style, including casing, mood, and prefixes.
   When history and guidance establish no convention, use Conventional Commits such as `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, or `chore:` with an imperative description.
   Never add AI attribution or session trailers.
6. Check for a breaking change only when the project has an existing public surface, such as a tagged release, published package, or established breaking-change convention.
   Removing, renaming, narrowing, or changing the meaning of a public API, CLI option, configuration key, schema, or relied-on default is breaking.
   With Conventional Commits, add `!` to the type and a `BREAKING CHANGE: <impact and migration>` footer.
   Otherwise explain the break and migration in the commit body.
7. Before committing a durable non-obvious constraint, or reversing an earlier decision, check whether the concern needs an ADR.
8. Commit only the intended paths, then report the hash, message, included files, and checks run.
