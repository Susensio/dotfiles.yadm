---
name: git-commit
description: Stages and commits pending work as atomic commits — one concern each, staged by explicit path, in this repo's existing message style. Use when asked to commit changes here.
---

# Git Commit Protocol

1. Inspect state: `git status` and `git diff --stat`.
2. **No-op guard:** nothing changed, or only scratch files under a job tmp dir — abort and say so rather than producing an empty commit.
3. **Atomicity:** changes spanning unrelated concerns get split, one commit per concern, each revertable on its own. Repeat steps 4-6 per concern. Landing in the same turn is not a reason to bundle.
4. **Selective staging:** stage by explicit path (`git add tmux/tmux.conf tmux/conf.d/10_keys.conf`). Never `git add .` — this tree routinely carries unrelated in-flight edits across config domains.
5. **Message:** capitalized imperative summary, no trailing period, naming the domain it touches. Match existing history — `Fix tmux bugs`, `Add fish fenv`, `Better autoenv`. This repo does not use conventional-commit prefixes.
6. Commit with `git commit -m "<message>"`.
