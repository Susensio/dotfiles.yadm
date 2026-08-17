# Dotfiles Workspace

XDG config repo for `~/.config`, managed with yadm.

- Shell and environment questions -- a variable is unset, login vs interactive
  shells, the bash-to-fish relay, `environment.d`, hot reload -- are answered in
  `docs/ENVIRONMENT_ARCHITECTURE.md`. Read it before investigating the process
  tree by hand.
- Fish functions live in `fish/functions/`. Scripts elsewhere are mostly bash --
  check the shebang before assuming fish syntax.
- Any script here that shells out to `tmux` (fish functions included) must
  isolate test runs against an explicit `-L <socket>` throwaway server -- never
  a bare `tmux` call in a test, it can hit the live session.
- Fan out along config domains -- `tmux`, `fish`, `nvim`, `mise`, `keyd` -- that
  is the seam that actually divides this repo. Not layers, not phases.
- Anything worth verifying against a live process goes to the `tester` agent,
  named with the domain's testing skill. The agent is a container; the isolation
  protocol lives in the skill. For tmux that is `tmux-testing`.
- Architecturally significant decisions about this setup -- tool or library
  choice, a structural change, a reversal of a prior decision -- belong in
  `docs/adr/` via the `adr` skill. Not auto-memory, not a comment.
  `ENVIRONMENT_ARCHITECTURE.md` describes what the setup is now; ADRs record why
  it got that way.
- Mark defects and unfinished work in place; there is no bugs file. `BUG:` plus
  one bare sentence on the line that is wrong. `TODO:` plus the trigger that
  unblocks it. A marker sits in the same diff as its fix, so fixing deletes it --
  a separate list would rot instead.
- A limitation deliberately accepted is not a bug. It belongs in the
  Consequences of an ADR, like `.xsession-errors` in ADR-0004.
- Anything broken with no single line to mark, or worth tracking to closure,
  goes to `gh issue create --repo Susensio/dotfiles.yadm`.

## tmux/

- Invoke the `tmux-config` skill before any tmux work. It carries the reference
  docs, the `conf.d/` layout, and the upstream-research routine.
- Running anything against a server -- a binding, a format, a popup -- is
  `tmux-testing`, via the `tester` agent. Never the live session.
