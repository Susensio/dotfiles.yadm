# Visual Testing tmux (Popups, Menus, Overlays)

How to actually *see* what a tmux config change renders — popups, menus, cursor visibility, pane borders, layout — from a non-interactive shell, without a human attaching to a real terminal.

## The problem

`tmux capture-pane` dumps the pane's **content buffer**.
Popups (`display-popup`), menus (`display-menu`), and anything else drawn as a client-side overlay are **not part of that buffer** — they're composited onto the client's screen at render time.
So running:

```bash
tmux -L test new-session -d -s t
tmux -L test display-popup -E 'sleep 5' &
tmux -L test capture-pane -p -t t   # popup is NOT in this output
```

tells you nothing about whether the popup appeared, where it landed, or what it looks like.
This is the trap: the check runs, exits 0, and proves nothing.

## The trick: use `tui-testing` to watch the client

A tmux client's rendered screen (content + overlays + cursor state) *is* visible to whatever terminal it's drawn into.
Because the tmux client is itself a TUI application, we can use the `tui-testing` skill to spin up a headless terminal emulator to watch it.

The architecture is clean:
1. **The Test Server** (`tmux-testing`): An isolated server running the config under test.
2. **The Eyeball** (`tui-testing`): A headless terminal emulator running `tmux -L <test-socket> attach`.

```bash
cd ~/.config/tmux

# 1. Build the scenario in the test server: real config, real pane layout
sock=$(${CLAUDE_SKILL_DIR}/scripts/tmux-test spawn tmux.conf)
tmux -L "$sock" split-window -h -t test
tmux -L "$sock" select-pane -t test.0

# 2. Spawn the eyeball (a headless terminal running the tmux client)
# (tui-testing is found relative to our own skill directory)
TUI_TEST="${CLAUDE_CONFIG_DIR}/skills/tui-testing/scripts/tui-test"
viewer=$("$TUI_TEST" spawn "tmux -L $sock attach -t test" 100 24)
sleep 1.5   # let the attach draw a full frame before doing anything else

# 3. Drive the thing under test on the test server
c=$(tmux -L "$sock" list-clients -F '#{client_name}')
tmux -L "$sock" display-popup -c "$c" -T " Pane... " -x R -y S -w 20 -h 6 -E 'sleep 6' &
sleep 1.5   # give the popup time to render before capturing

# 4. Capture the screen via the viewer — this sees the popup, borders, cursor, everything
"$TUI_TEST" capture "$viewer"

wait
${CLAUDE_SKILL_DIR}/scripts/tmux-test kill "$sock"
"$TUI_TEST" kill "$viewer"
```

This is exactly how a positioning bug in `scripts/which-key`'s popup was caught: `-x R` turned out to be pane-relative, not client-relative, which only became visible once the rendered screen — not the content buffer — was inspected.

## Driving it programmatically (Python)

For anything beyond "fire one popup and look," script the drive/capture loop instead of hand-timing sleeps in bash.

```python
import subprocess, time, os

# This recipe assumes it's running within the context of tmux-testing
SKILL_DIR = os.environ["CLAUDE_SKILL_DIR"]
TMUX_TEST = f"{SKILL_DIR}/scripts/tmux-test"
TUI_TEST = os.path.normpath(f"{SKILL_DIR}/../../../claude/skills/tui-testing/scripts/tui-test")

# Start the test server (using tmux-test)
S = subprocess.run([TMUX_TEST, "spawn", "tmux.conf"], capture_output=True, text=True).stdout.strip()

# Start the viewer (using tui-test)
viewer = subprocess.run(
    [TUI_TEST, "spawn", f"tmux -L {S} attach -t test", "100", "24"],
    capture_output=True, text=True
).stdout.strip()
time.sleep(1.5)

c = subprocess.run(
    ["tmux", "-L", S, "list-clients", "-F", "#{client_name}"],
    capture_output=True, text=True,
).stdout.strip()

# A script invoked manually doesn't inherit $TMUX —
# set it explicitly so the script's own `tmux` calls target the right client/socket.
env = dict(os.environ)
env["TMUX"] = f"/tmp/tmux-{os.getuid()}/{S},0,0"

subprocess.run(["tmux", "-L", S, "switch-client", "-c", c, "-T", "pane"])
p = subprocess.Popen(["./scripts/which-key", "pane", c], env=env)
time.sleep(1.5)

screen = subprocess.run([TUI_TEST, "capture", viewer], capture_output=True, text=True).stdout
for i, line in enumerate(screen.splitlines(), 1):
    print(f"{i:2d} |{line}|")

p.kill()
subprocess.run([TMUX_TEST, "kill", S])
subprocess.run([TUI_TEST, "kill", viewer])
```

## Reading side effects instead of pixels

Rendering isn't the only thing worth checking.
For anything else (did zoom toggle, did pane count change, did an option get set) just query the test server directly with `display-message -p` or `show-options` — no viewer needed, those aren't overlay-only state.

## Gotchas

- **Popups grab client input.**
  `send-keys -c <client>` sent to the test server while a popup is open is swallowed by the popup, not the pane underneath. If a script needs to prove a key reached the popup, have the popup write the key to a `mktemp` file and read the file back.
- **Sleep long enough to render**, but no more — 1–1.5s after `attach` / after triggering a popup is typically enough; too little gives a half-drawn frame, false negatives.
- **Always kill both servers when done**, including on early exit / failure paths.
- **`capture` gives plain text**, no color. It's the right tool for structure/position/borders/text content, not colors.
