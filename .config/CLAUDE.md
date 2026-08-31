# Dotfiles Workspace

XDG config repo for `~/.config`, managed with yadm.

- The yadm worktree root is `$HOME`, not this directory: `git rev-parse --show-toplevel` returns `~`, so never derive a project root from it.
  Use `yadm` for every git operation, from any directory.
  Plain `git` happens to work inside `.config` via an untracked pointer file that a fresh machine does not have until `yadm/bootstrap` recreates it.
- Shell and environment questions -- a variable is unset, login vs interactive shells, the bash-to-fish relay, `environment.d`, hot reload -- are answered in `docs/environment-architecture.md`.
  Read it before investigating the process tree by hand.
- Before writing config syntax you have not verified in this session, check the tool's manpage or `--help`.
- Fan out along config domains -- `tmux`, `fish`, `nvim`, `mise`, `keyd`.
  That is the seam that divides this repo.
  Not layers, not phases.
- Decisions about this setup belong in `.config/docs/adr/`; a reason with a line to sit beside is a comment there instead.
  Ask the `adr` skill which -- it holds the test, and never auto-memory.
- Open work with no single line to mark lives in `docs/BACKLOG.md`; `rg -n 'BUG:|TODO:'` lists the rest.
- A limitation deliberately accepted is not a bug.
  It goes in the Consequences of an ADR, like `.xsession-errors` in ADR-0004.
- The `report-issue` skill files upstream, never against this repo.
- Commit messages here are capitalized imperative, no trailing period, naming the domain touched -- `Fix tmux bugs`, `Add fish fenv`.
  No conventional-commit prefixes.
  Stage by explicit path; this tree carries in-flight edits across several config domains at once.

## claude/

- All Claude Code config goes under `.config/claude/`, as real files -- `agents/`, `skills/`, `rules/`, `hooks/` and `CLAUDE.md`.
  `CLAUDE_CONFIG_DIR` points there, so that directory is also where the credentials, session transcripts and plugins live.
  Only the hand-maintained config is tracked; `yadm/exclude` and `.config/claude/.gitignore` keep the rest out.
  Paths written into `settings.json` are absolute -- a move breaks the hooks and the statusline until they are rewritten.

## tmux/

- Invoke the `tmux-config` skill before any tmux work.
  It carries the reference docs and the upstream-research routine.
- Anything run against a server -- a binding, a format, a popup, a fish function that shells out to `tmux` -- is `tmux-testing`, which owns the `-L <socket>` isolation protocol.
