# Driving a throwaway server by hand

For the cases `tmux-test spawn` cannot express.
Everything here is what the script already does; doing it by hand means doing all of it.

- **Always pass an explicit `-L <socket>`** to every single `tmux` invocation.
  A bare `tmux ...` targets `$TMUX`, the user's live server.
- **Never `kill-server`, `kill-session`, `kill-window` or `kill-pane` without `-L`**, and only ever against a socket your own test created.
- **Name the socket `tmuxtest_<what>`** (`tmuxtest_bell`, `tmuxtest_inner`, `tmuxtest_outer`), never the default socket and never a name real scripts use (`*_scratchpad`).
  The prefix is what lets `tmux-test kill` accept it and `tmux-test sweep` find it; a socket named anything else is refused by both and leaks.
- **Always pass `-f`** so the throwaway never falls back to the user's live config.
  `-f <config-under-test>` is the normal form; `-f /dev/null` plus `source-file` is for per-file error reporting or sourcing fragments incrementally.
- **Scrub the inherited environment.**
  A test script that shells out inherits `$TMUX`; `unset TMUX` so nested commands cannot fall through to the real server.
- **Clean up only what you created** — kill the server *and* `rm -f` its socket file on every exit path, including failures.

`tmux-test sweep` then kills every leftover `tmuxtest_*` server, including the ones spawned here.
It touches no socket named otherwise, so the `tuitest_*` servers `tui-testing` runs are unaffected.
