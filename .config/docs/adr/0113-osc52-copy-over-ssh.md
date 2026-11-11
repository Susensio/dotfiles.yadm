# ADR-0113: Copy over SSH with OSC 52 through the clipboard script and SSH-only set-clipboard external, instead of X11 forwarding, a clipboard daemon or external everywhere

Status: Accepted
Date: 2026-11-11

## Context

`y` in tmux copy mode worked on the laptop but not on the `nuc` over SSH.
Two faults stacked.
The `clipboard` script forced `DISPLAY=:0`, so it always chose `xsel` on the headless `nuc` and its `tmux` and fallback branches were unreachable.
And tmux 3.7 with `set-clipboard off` also silences `tmux load-buffer -w`, so even the OSC 52 path stayed in the tmux buffer.

Every copy path (nvim, tmux `y`, mouse copy, fish pipes) goes through `clipboard`, which also carries the clipboard-versus-primary choice.
The mouse bindings copy to primary with `copy-pipe`, which also stores a tmux buffer.

## Decision

The `clipboard` script treats a session with `SSH_CONNECTION` as its own platform, ahead of Wayland and X11, and drops the forced `DISPLAY` default.
Inside tmux it runs `tmux load-buffer -w -`; outside tmux it writes the OSC 52 sequence to `/dev/tty` and keeps a local copy for `paste`.
`tmux/conf.d/21_copy.conf` sets `set-clipboard external` only when `SSH_CONNECTION` is set, so apps still cannot set tmux buffers through OSC 52.

Discarded:

- X11 forwarding or a reverse-tunnel daemon (`lemonade`, `clipper`): forwarding setup per host, a daemon on both ends, and the daemon is the only route to two-way paste.
- `external` everywhere: every tmux buffer would overwrite the laptop clipboard, so each mouse selection would, breaking the primary split the mouse bindings rely on.
  It could work with the mouse bindings moved to buffer-less `pipe` variants; that was not tried.
- Writing OSC 52 to the tmux client's tty from the script: needs no tmux option, but bypasses tmux's output and can interleave with a redraw.

## Consequences

Copy over SSH needs no forwarding, daemon or per-host setup and works over any SSH path the terminal supports.
Paste from the laptop clipboard into the `nuc` is not possible; the terminal's own paste (`ctrl+shift+v`) types it in, and `clipboard paste` on the `nuc` returns only what that host last copied.
A tmux server started outside SSH, or one that outlives its login without `SSH_CONNECTION`, keeps `set-clipboard off` and falls back to the tmux buffer until restarted.
Non-interactive `ssh nuc 'cmd'` has no `argc` on `PATH`, so a script there must call `clipboard` through `fish -lc`.
