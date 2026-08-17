---
name: tmux-testing
user-invocable: false
description: Use when running anything against a tmux server — checking that tmux.conf or conf.d/*.conf loads, verifying a binding fires, expanding a format, or seeing what a popup or menu actually renders.
---

# Tmux Testing

Running things against tmux. Reading or editing the config is `tmux-config`.

## 0. Never touch the user's running tmux (non-negotiable)

The user is very likely *inside* tmux right now — quite possibly the session
this agent was launched from. Every test, experiment, or reproduction runs on
its own throwaway server, fully isolated.

`${CLAUDE_SKILL_DIR}/scripts/tmux-test` implements the protocol in code,
including the cleanup paths that are easy to forget.
`tmux-test --help` lists the subcommands. Prefer it to hand-typed `tmux -L`
commands: it passes `-L` on every invocation and refuses to operate on a socket
it did not create.

The rules it enforces, and what to follow for the rare check driven by hand:

- **Always pass an explicit `-L <socket>`** to every single `tmux` invocation in
  a test. A bare `tmux ...` targets `$TMUX` (the user's server) — one stray
  `kill-server`, `set -g`, or `kill-session` there wrecks their live workspace.
- **Never `kill-server`, `kill-session`, `kill-window`, or `kill-pane` without
  `-L`**, and only ever against sockets your own test created.
- **Use a distinctive test socket name** (`test_bell`, `inner`, `outer`, ...),
  never the default socket, and never the user's socket name + suffix
  conventions used by real scripts (e.g. `*_scratchpad`).
- **Always pass `-f`** so the throwaway never falls back to the user's live
  config. `-f <config-under-test>` is the normal form. Use `-f /dev/null` plus
  `source-file` only when you need per-file error reporting or want to source
  fragments incrementally.
- **Scrub the inherited environment.** A test script that shells out inherits
  `$TMUX`; `unset TMUX` (or set it to the test socket explicitly) so nested
  commands can't fall through to the real server.
- **Clean up only what you created** — kill your test servers *and* `rm -f`
  their socket files on every exit path, including failures.

If a check genuinely cannot be done in isolation, stop and tell the user what
you'd need to run against their live server, rather than doing it.

## 1. Pick the lightest check that answers the question

- Anything queryable as plain state — options, formats, key tables — reads out
  of `tmux-test eval`, `display-message -p`, or `show-options`.
- The nested-session recipe only when something must actually be *seen*.
- Run `tmux -V` before trusting an option or format: both vary by version.

`capture-pane` cannot see popups, menus, or other client-side overlays — it only
dumps the pane content buffer. Never trust a `capture-pane` check as proof a
popup rendered correctly.

## 2. Visual checks (popups, menus, overlays)

Nest a second tmux server that attaches to the first, and capture *that* pane
instead. The `nested-*` subcommands of `tmux-test` drive it — spawn, run,
capture, eval, kill. Full recipe, gotchas, and a Python driver pattern:
`references/nested_session_visual_testing.md`.

Captured frames are large and often need several tries to time right. That is
work for the `tester` agent, not for the calling conversation — hand it over
with what's under test and what counts as a pass, and get back a verdict.
