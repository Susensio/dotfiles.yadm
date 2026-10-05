# ADR-0086: Follow the pointer to newly focused windows from a window.open handler, instead of a direct cursor move or waiting on upstream

Status: Accepted
Date: 2026-10-05

## Context

The pointer should keep up with the focus, but a window should give it back where it was left rather than at a fixed spot.
Omarchy ships `cursor:warp_on_change_workspace = 1`, which lands the pointer in the middle of the last focused window of every workspace it switches to, and `cursor:persistent_warps` replaces that middle with the pointer's remembered offset, which Hyprland honours only while it falls inside the target window.
Hyprland does not move the pointer when a window opens and takes focus: `CWindow::onMap` focuses through `fullWindowFocus` with the new-window reason and never calls `CWindow::warpCursor()`.
The only native path that moves the pointer onto a window is xdg-activation, and it is skipped here twice over: `CWindow::activate()` returns as soon as the window already holds focus, and Omarchy's terminal launch (`omarchy-launch-terminal` → `uwsm-app -- xdg-terminal-exec`) hands out no activation token.
So a new terminal left the pointer on the previous window, and with `input:follow_mouse = 1` the next mouse movement gave focus to whatever sat under it, undoing the new window's focus.
The alternatives were to leave it, to set `cursor:no_warps`, to re-dispatch focus from a handler, to move the pointer directly with computed window geometry, or to wait for upstream.
Upstream had already declined: issue #5745 asked for exactly this and PR #5777 implemented it in the window-open path, but the PR was closed unmerged for inactivity.
Hyprland 0.56.2's Lua config exposes the `window.open` event, emitted after layout, and `hl.dsp.focus` accepts a window object, so a handler needs no selector string.

## Decision

`~/.config/hypr/looknfeel.lua` enables `cursor:persistent_warps` and registers a `window.open` handler that re-dispatches focus, but only when the new window is the active one.

```lua
hl.on("window.open", function(w)
  local active = hl.get_active_window()
  if active == w then
    hl.dispatch(hl.dsp.focus({ window = w }))
  end
end)
```

The guard is load-bearing: `Actions::focus` switches workspaces when its target lives elsewhere, so without it every background window would drag the view to its own workspace.
Re-dispatching focus was chosen over moving the pointer directly because it reuses Hyprland's own pointer logic and so inherits `persistent_warps` and any later fix to it, while `Actions::moveCursor` is a forced move that would override `cursor:no_warps` instead of obeying it.

## Consequences

The pointer follows a new terminal, and equally any dialog or popup that takes focus, because the handler does not filter by class or floating state.
Re-dispatching focus re-runs the whole focus path, since `Actions::focus` passes a null surface and `rawWindowFocus`'s early return for an already-focused window compares against the real one.
The visible effects are a second `activewindow` event, a repeated focus-rule refresh and a restarted focus animation; the focus history and the keyboard focus are both unaffected, because the history tracker erases before appending and a null surface falls back to the window's own.
Accepted: every new window that takes focus pulls the pointer, dialogs included; a class or floating filter in the handler is the one-line way back if that grates.
Accepted: the handler degrades to a no-op re-focus if `cursor:no_warps` is ever enabled, which is the intended reading of that setting.
Accepted: this works around a feature upstream declined to add, and becomes redundant if a new-window option or PR #5777's approach ever lands.

## Corrections

2026-10-09: The handler was completed with a pointer refresh.
Re-dispatching focus warps through `CWindow::warpCursor()`, which moves only the hardware cursor and never calls `setPointerFocus`, and `fullWindowFocus` refreshes the pointer only under `input:follow_mouse = 0`, so with the default `1` a client kept the pointer coordinates of the last real motion and hit-tested the next click at the old spot.
The handler now re-issues the warp in place through `hl.dsp.cursor.move` while `cursor:no_warps` is off, which runs `simulateMouseMovement` and re-sends pointer motion to the newly focused client.
