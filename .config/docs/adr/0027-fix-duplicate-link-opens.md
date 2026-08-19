# ADR-0027: Disable Claude Code's own click-to-open to fix duplicate link opens

Status: Accepted
Date: 2026-08-17

## Context

Clicking a URL printed by Claude Code opened two browser tabs.
Suspected tmux/gnome-terminal crosstalk (`terminal-features "*:hyperlinks"`, `allow-passthrough`) first, but neither is the cause: passthrough only routes raw escape sequences to the outer terminal and doesn't touch mouse-click handling.
Upstream (anthropics/claude-code#76110, confirmed by a maintainer) traces it to Claude Code's fullscreen TUI enabling mouse reporting and running its own click-to-open dispatcher, which fires on the same click the terminal (gnome-terminal/VTE) already handles natively via OSC 8 — two independent `xdg-open` calls per click.
Not specific to this dotfiles setup or to tmux.

## Decision

Set `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` in the `env` block of `~/.claude/settings.json`, not `environment.d/` under [ADR-0001](0001-centralize-environment-variables.md): only Claude Code reads this variable, so it belongs in the tool's own config next to the rest of its settings rather than the session-wide store meant for variables shared across shells, systemd services, and X11 apps.

## Consequences

The terminal's native link handling is now the only one that fires — one tab per click.
Trade-off: this also disables Claude Code's own click/drag mouse handling inside the fullscreen TUI, so text selection there falls back to the terminal's native selection (e.g. shift+drag).
Switching to `/tui default` avoids that trade-off but gives up fullscreen mode entirely, which costs more than losing in-TUI drag-select.
Revisit once upstream gates its internal dispatch on terminal capability, per the fix bcherny described in #76110.

