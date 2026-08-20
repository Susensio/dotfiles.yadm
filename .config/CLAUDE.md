# Dotfiles Workspace

XDG config repo for `~/.config`, managed with yadm.

- The yadm worktree root is `$HOME`, not this directory: `git rev-parse --show-toplevel` returns `~`, so never derive a project root from it.
  Use `yadm` for every git operation, from any directory.
  Plain `git` happens to work inside `.config` via an untracked pointer file that a fresh machine does not have until `yadm/bootstrap` recreates it.
- Shell and environment questions -- a variable is unset, login vs interactive shells, the bash-to-fish relay, `environment.d`, hot reload -- are answered in `docs/ENVIRONMENT_ARCHITECTURE.md`.
  Read it before investigating the process tree by hand.
- Fish functions live in `fish/functions/`.
  Scripts elsewhere are mostly bash -- check the shebang before assuming fish syntax.
- Fan out along config domains -- `tmux`, `fish`, `nvim`, `mise`, `keyd`.
  That is the seam that divides this repo.
  Not layers, not phases.
- Anything worth verifying against a live process goes to the `tester` agent, named with the domain's testing skill.
  For tmux that is `tmux-testing`.
- Architecturally significant decisions about this setup -- tool or library choice, a structural change, a reversal of a prior decision -- belong in `.config/docs/adr/` via the `adr` skill.
  Not auto-memory, not a comment.
- A limitation deliberately accepted is not a bug.
  It goes in the Consequences of an ADR, like `.xsession-errors` in ADR-0004.
- Mark defects and unfinished work in place; there is no bugs file.
  `BUG:` plus one bare sentence on the line that is wrong.
  `TODO:` plus the trigger that unblocks it.
- Anything broken with no single line to mark, or worth tracking to closure, goes to `gh issue create --repo Susensio/dotfiles.yadm`.
- Commit messages here are capitalized imperative, no trailing period, naming the domain touched -- `Fix tmux bugs`, `Add fish fenv`.
  No conventional-commit prefixes.
  Stage by explicit path; this tree carries in-flight edits across several config domains at once.

## agents/

- New Claude Code config goes under `.config/agents/`, symlinked back into `~/.claude/`, like `agents/`, `skills/`, `rules/` and `GLOBAL.md`.

## tmux/

- Invoke the `tmux-config` skill before any tmux work.
  It carries the reference docs, the `conf.d/` layout, and the upstream-research routine.
- Anything run against a server -- a binding, a format, a popup, a fish function that shells out to `tmux` -- is `tmux-testing`, which owns the `-L <socket>` isolation protocol.
  Never the live session, never a bare `tmux` in a test.
