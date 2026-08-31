---
name: tmux-testing
user-invocable: false
description: Use when running anything against a tmux server — checking that tmux.conf or conf.d/*.conf loads, verifying a binding fires, expanding a format, or seeing what a popup or menu actually renders.
---

# Tmux Testing

Running things against tmux.
Reading or editing the config is `tmux-config`.

## 0. Never touch the user's running tmux (non-negotiable)

The user is very likely *inside* tmux right now — quite possibly the session this agent was launched from.
A bare `tmux ...` targets `$TMUX`, which is that session: one stray `kill-server`, `set -g` or `kill-session` wrecks their live workspace.

`${CLAUDE_SKILL_DIR}/scripts/tmux-test` owns the life of every test server, and `tmux-test --help` lists its subcommands:

```bash
s=$(tmux-test spawn conf.d/31_visual.conf)   # fresh socket, name printed
w=$(tmux-test window "$s" nvim git)          # panes reporting those commands
tmux-test eval "$s" '#{E:automatic-rename-format}' "$w"
tmux-test kill "$s"                          # server killed, socket file removed
```

Spawning and killing go through it, every time.
It passes `-L` on every call, unsets `$TMUX` before anything runs, refuses to kill a socket it did not create, and removes the socket file and its fakebin on every exit path including failure.
It also carries two findings that cost hours to rederive: pane commands are typed through a fakebin, because under a fish default-shell the argument form leaves `pane_current_command` reporting `fish`; and panes are addressed by id, because `pane-base-index` varies with the config under test.

Talking to a socket it handed you is expected and safe — `tmux -L "$s" list-keys`, `show-options`, `source-file` — because `$s` came from `spawn` and the `-L` is already in hand.

Where `spawn` cannot express the case — per-file `source-file` error reporting, `-f /dev/null`, a server that must outlive one command — [`references/by_hand.md`](references/by_hand.md) carries the protocol to follow instead.
Read it at that point, and follow it exactly.

If a check genuinely cannot be done in isolation, stop and tell the user what you would need to run against their live server, rather than doing it.

## 1. Pick the lightest check that answers the question

- Anything queryable as plain state — options, formats, key tables — reads out of `tmux-test eval`, `display-message -p`, or `show-options`.
- A visual check only when something must actually be *seen*.
- Run `tmux -V` before trusting an option or format: both vary by version.

`capture-pane` cannot see popups, menus, or other client-side overlays — it only dumps the pane content buffer.
Never trust a bare `capture-pane` check as proof a popup rendered correctly.

## 2. Visual checks (popups, menus, overlays)

Because popups are client-side overlays, they don't appear in the pane buffer. To see them, we use the `tui-testing` skill to watch a tmux client attach to our test server.
Full recipe, gotchas, and a Python driver pattern: `references/visual_testing.md`.

Captured frames are large and often need several tries to time right.
That is work for the `tester` agent, not for the calling conversation — hand it over with what's under test and what counts as a pass, and get back a verdict.
