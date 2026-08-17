# Visual Testing via Nested tmux Sessions

How to actually *see* what a tmux config change renders — popups, menus,
cursor visibility, pane borders, layout — from a non-interactive shell,
without a human attaching to a real terminal.

## Use `scripts/tmux-test nested-*`, not raw commands

`tmux-test` wraps this whole recipe: `nested-spawn`, `nested-run`,
`nested-capture`, `nested-eval`, `nested-kill`. It only ever touches sockets
it generated itself — passing anything else is refused — so it's the
allow-listed entry point for `tmux-tester`. Read the rest of this doc for
*why* each step exists and the gotchas below; drive it through the script
rather than typing the raw `tmux -L inner/outer ...` commands by hand.

```bash
pair=$(scripts/tmux-test nested-spawn tmux.conf 100 24)
inner=${pair% *}; outer=${pair#* }

scripts/tmux-test nested-run "$inner" "$outer" \
    display-popup -T " Pane... " -x R -y S -w 20 -h 6 -E 'sleep 6' &
sleep 1.5
scripts/tmux-test nested-capture "$inner" "$outer"

scripts/tmux-test nested-kill "$inner" "$outer"
```

## Ground rule: isolation is not optional

You are almost certainly running *inside* the user's tmux. Everything below
happens on throwaway servers with explicit `-L` sockets, and that is the
point — not a stylistic choice.

- **Every `tmux` call in a test carries `-L <socket>`.** A bare `tmux` targets
  `$TMUX`, i.e. the user's live server. The dangerous ones are `kill-server`,
  `kill-session`, `set -g`, `set-hook -g`, `source-file` — each of which
  silently mutates or destroys the workspace you're working in.
- **Only ever kill sockets your own test created.** Never a blanket
  `tmux kill-server`, never `pkill tmux`.
- **Pick names that can't collide** with the user's real sockets or the socket
  conventions their scripts use (e.g. `scripts/scratchpad` derives
  `<socket>_scratchpad` — don't reuse that shape in a test).
- **`unset TMUX`** (or set it explicitly to the test socket, as in the Python
  pattern below) in anything that shells out, so a script under test can't
  fall through to the real server.
- **`-f /dev/null`** on throwaway `new-session` calls; load the config under
  test with an explicit `source-file`. Never `source-file` into the user's
  server to "check it parses" — start a test server and source it there.
- **Clean up on every exit path**, failures included: kill your servers and
  `rm -f` their socket files.

If something truly can't be verified in isolation, say so and hand the command
to the user instead of running it against their session.

## The problem

`tmux capture-pane` dumps the pane's **content buffer**. Popups
(`display-popup`), menus (`display-menu`), and anything else drawn as a
client-side overlay are **not part of that buffer** — they're composited
onto the client's screen at render time. So running:

```bash
tmux -L test new-session -d -s t
tmux -L test display-popup -E 'sleep 5' &
tmux -L test capture-pane -p -t t   # popup is NOT in this output
```

tells you nothing about whether the popup appeared, where it landed, or
what it looks like. This is the trap: the check runs, exits 0, and proves
nothing.

## The trick: nest a second tmux server as the "eyeball"

(This is what `nested-spawn`/`nested-capture` do internally — read on for
the mechanism, not as a separate set of commands to run.)

A tmux client's rendered screen (content + overlays + cursor state) *is*
visible to whatever terminal it's drawn into. So attach the client we
want to inspect **inside a pane of a second, independent tmux server**.
That outer pane is now a terminal emulator showing exactly what a human
would see — popups included — and `capture-pane` on the *outer* pane
captures it as plain text.

Two separate servers, on separate sockets, so they can't see each other's
state:

- **`inner`** — the session/config actually under test.
- **`outer`** — a throwaway session whose only pane runs
  `tmux -L inner attach`, i.e. it's *watching* the inner client.

```bash
cd ~/.config/tmux

# Always start clean — stale sockets from a previous run cause confusing failures
tmux -L inner kill-server 2>/dev/null
tmux -L outer kill-server 2>/dev/null

# 1. Build the scenario in `inner`: real config, real pane layout
tmux -L inner -f /dev/null new-session -d -s t -x 100 -y 24
tmux -L inner source-file "$PWD/tmux.conf" 2>&1   # check this prints nothing on stderr
tmux -L inner split-window -h -t t
tmux -L inner select-pane -t t.0                  # set up whichever pane should be "active"

# 2. `outer` attaches to `inner` as its pane's command — this IS the eyeball.
#    Match -x/-y to `inner`'s size or the rendered layout won't line up.
tmux -L outer -f /dev/null new-session -d -s o -x 100 -y 24 "tmux -L inner attach -t t"
sleep 1.5   # let the attach draw a full frame before doing anything else

# 3. Drive the thing under test on the INNER server
c=$(tmux -L inner list-clients -F '#{client_name}')
tmux -L inner display-popup -c "$c" -T " Pane... " -x R -y S -w 20 -h 6 -E 'sleep 6' &
sleep 1.5   # give the popup time to render before capturing

# 4. Capture the OUTER pane — this sees the popup, borders, cursor, everything
tmux -L outer capture-pane -p -t o | cat -A | sed 's/\$$//' | nl -ba

wait
tmux -L inner kill-server 2>/dev/null
tmux -L outer kill-server 2>/dev/null
```

This is exactly how a positioning bug in `scripts/which-key`'s popup was
caught: `-x R` turned out to be pane-relative, not client-relative, which
only became visible once the rendered screen — not the content buffer —
was inspected.

## Driving it programmatically (Python)

For anything beyond "fire one popup and look," script the drive/capture
loop instead of hand-timing sleeps in bash. Pattern used for regression
runs across several key tables:

```python
import subprocess, time, os

S = "inner"
c = subprocess.run(
    ["tmux", "-L", S, "list-clients", "-F", "#{client_name}"],
    capture_output=True, text=True,
).stdout.strip()

# A script invoked manually (not via tmux run-shell) doesn't inherit $TMUX —
# set it explicitly so the script's own `tmux` calls target the right client/socket.
env = dict(os.environ)
env["TMUX"] = f"/tmp/tmux-{os.getuid()}/{S},0,0"

subprocess.run(["tmux", "-L", S, "switch-client", "-c", c, "-T", "pane"])
p = subprocess.Popen(["./scripts/which-key", "pane", c], env=env)
time.sleep(1.5)

screen = subprocess.run(
    ["tmux", "-L", "outer", "capture-pane", "-p", "-t", "o"],
    capture_output=True, text=True,
).stdout
for i, line in enumerate(screen.splitlines(), 1):
    print(f"{i:2d} |{line}|")

p.kill()
```

Looping this over several key tables (`prefix`, `pane`, `session`,
`config`, ...) turns it into a real regression suite — run before and
after a config change, diff the captured frames.

## Reading side effects instead of pixels

Rendering isn't the only thing worth checking. Formats read from the
*outer* client reflect the inner client's actual visual state, which is
useful for things a screen-scrape is clumsy at:

```bash
# Cursor visibility (hidden while a popup owns the screen)
tmux -L outer display -p -t o '#{cursor_flag}'   # 1 = visible, 0 = hidden
```

For anything else (did zoom toggle, did pane count change, did an option
get set) just query the *inner* server directly with `display-message -p`
or `show-options` — no nesting needed, those aren't overlay-only state.

## Gotchas

- **Popups grab client input.** `send-keys -c <client>` sent to the inner
  client while a popup is open is swallowed by the popup, not the pane
  underneath — this is real tmux behavior, not a test artifact. If a
  script needs to prove a key reached the popup, have the popup write the
  key to a `mktemp` file and read the file back, rather than trying to
  observe a side effect on the base client.
- **`-x`/`-y` must match** between the scenario you built in `inner` and
  the pane size you give `outer`, or the captured frame is a truncated
  view, and positioning math (`client_width`, `-x R`, etc.) won't match
  what a real terminal would show.
- **Sleep long enough to render**, but no more — 1–1.5s after `attach` /
  after triggering a popup is typically enough; too little gives a
  half-drawn frame, false negatives.
- **Always kill both servers when done**, including on early exit /
  failure paths, and clean up the socket files
  (`/tmp/tmux-$(id -u)/inner`, `/tmp/tmux-$(id -u)/outer`) — leftover
  sockets from a killed-but-not-cleaned run cause the *next* run's
  `new-session` to attach to stale state instead of starting fresh.
- **`-f /dev/null`** on both `new-session` calls avoids picking up the
  user's real `~/.tmux.conf` / XDG config for the throwaway sessions —
  `inner` should load *only* the config under test, via an explicit
  `source-file`.
- **`capture-pane -p` gives plain text**, no color. It's the right tool
  for structure/position/borders/text content. If a color/style
  regression is in question, that's a different check (e.g. diff the
  option values or styles directly via `show-options`), not something to
  chase through the captured frame.

## When to reach for this

Good for: popups, menus, status-bar rendering, pane borders/layout,
cursor visibility, anything a human would need to look at the terminal
to confirm.

Overkill for: anything observable as a plain option value, pane count, or
other state queryable directly from the inner server with
`display-message -p` / `show-options` — check that directly, it's faster
and doesn't need a second server.
