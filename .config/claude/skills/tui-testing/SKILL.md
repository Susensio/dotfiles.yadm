---
name: tui-testing
user-invocable: false
description: Use when needing to run a TUI (like nvim, fzf, or any visual interactive terminal app) headlessly, send it keystrokes, and capture its screen state.
---

# TUI Testing

Running interactive terminal applications (TUIs) headlessly and scraping their screen state.

## Core concepts

TUIs draw to a terminal. To test them programmatically without a human and a real screen, we spin up a throwaway terminal emulator in the background, run the command inside it, and scrape its buffer.

`${CLAUDE_SKILL_DIR}/scripts/tui-test` provides this headless terminal wrapper (implemented via a throwaway tmux server, hidden from the caller).

```bash
# 1. Spawn a headless terminal running the TUI (e.g. nvim, fzf, or a bash script)
id=$(${CLAUDE_SKILL_DIR}/scripts/tui-test spawn "nvim file.txt")

# 2. Wait for it to render
sleep 1.5

# 3. Send keystrokes
${CLAUDE_SKILL_DIR}/scripts/tui-test send-keys "$id" "iHello" Escape

# 4. Capture the visual state of the terminal
${CLAUDE_SKILL_DIR}/scripts/tui-test capture "$id"

# 5. Clean up
${CLAUDE_SKILL_DIR}/scripts/tui-test kill "$id"
```

## Gotchas

- **Always kill the test environment** (`tui-test kill "$id"`) on every exit path, including failures, to avoid leaking background processes.
- **Sleep long enough to render**: TUIs need time to draw frames after starting or receiving keystrokes. 1–1.5s is usually safe. Too little gives a half-drawn frame or false negatives.
- **Literal vs Control keys**: When sending text strings (especially those with spaces or dashes), use `-l --` so tmux doesn't parse them as special keys: `${CLAUDE_SKILL_DIR}/scripts/tui-test send-keys "$id" -l -- "text to type"`.
- **Python REPLs**: If your test involves spawning an interactive python shell, always export `PYTHON_BASIC_REPL=1` first. Modern Python's advanced readline and auto-indent will scramble `send-keys` and screen captures.
- **The captured frame is plain text**, with ANSI colors stripped. It's for verifying layout, text, popups, and borders, not color styling.
