# ADR-0076: Drive Hyprland's window actions with chords instead of the window-mode submap, adopting Omarchy's power, capture, notification and panel families

Status: Accepted
Date: 2026-09-29
Supersedes: 0055 (partially — the submap and the system keys; the Super-mirrors-tmux letters stand)

## Context

[ADR-0055](0055-hyprland-super-mirrors-tmux.md) put resize, swap and workspace-to-monitor behind the Super + P window mode, mirroring tmux's pane table. The mirror cost more than it bought: every action took two keystrokes for a handful of fixed-argument operations, Hyprland shows nothing while a submap is active (a forgotten mode silently turned hjkl into resizing until Escape), and covering that gap meant a bar widget and an upstream menu patch for a feature only one layer used.

Meanwhile Omarchy's QoL commands sat unbound because the default binding set was off per [ADR-0055](0055-hyprland-super-mirrors-tmux.md): the suspend entry point that ADR-0069 gave every caller, the capture family beyond PrtSc, the notification family beyond dismiss, and the bar panels. The Omarchy menu reached them all, but keys on the Super layer were free.

Two collisions shaped the letters. Audio's first letter V is taken on the same Super + Ctrl layer by the clipboard manager that bindings.lua keeps from Omarchy's clipboard.lua. Agents sit on bare Super + A, so the panel layer's Ctrl modifier distinguishes the audio panel without displacing the agent pick. The submap's bar widget, installed as the indicator half of a backlog item, would have nothing left to indicate once no submaps existed.

## Decision

Window actions are chords on the same hjkl letters, one modifier per action: Super + Ctrl resizes (repeatable, 40 px), Super + Shift swaps, Super + Alt sends the window to a monitor. The Super + P window mode is deleted, and Super + P is freed.

The power key climbs modifiers, all working on the lock screen: power suspends (`systemctl suspend-then-hibernate`, inheriting ADR-0069's policy and the pre-suspend lock from `omarchy-sleep-lock.service`), Ctrl + power locks, Super + power opens the system menu, Alt + power forces the screensaver.

The Print key climbs the capture family: plain prints the screenshot, Super opens the capture menu, Shift runs OCR, Ctrl scans a QR code, Alt picks a color.

Notifications complete around the existing dismiss keys: Super + Ctrl + comma opens the notification history (Omarchy's slot for it, deliberately kept on the Super + Ctrl "panel-like" layer), and the silencing toggle moves to Super + Alt + comma. Invoking the last notification is left unbound.

Bar panels hang off Super + Ctrl + first letter: W network, B bluetooth, A audio, D display, P power. The clipboard manager keeps Super + Ctrl + V: it is a shell overlay, not a panel, so it stays off the panel layer.

The panel layer gained a second modifier, Super + Alt + the same letter flipping the thing itself instead of opening its panel: W toggles the wifi radio through NetworkManager (no Omarchy command exists; `nmcli radio wifi` is the lever, and an upstream wrapper is backlog), B rfkills the bluetooth adapter through `omarchy-bluetooth-power toggle` (rfkill persists across reboots, bluetoothctl's Powered does not), and P cycles the power profile through a local `omarchy-powerprofiles-cycle`, which wraps backwards through the list (performance to power-saver to balanced) via `omarchy-powerprofiles-set autodetect` and notifies with the profile's icon. P was first put on Super + Alt + power and moved beside the panel letter within the hour.

Zen mode replaced the square-aspect toggle, and it is maximize itself: Super + Z keeps maximizing, and a workspace rule on `f[1]` (maximized) widens `gaps_out` to 160 on each side, about 4:3 on this display, under the bar and inside the normal gaps. Maximize keeps the window in the tiling tree and hides the other tiles without moving them, so nothing reflows and un-maximizing returns every window to its slot; the existing `fullscreen_state_internal = 1` rule gives it maximize's border colour and dims around it. Omarchy ships a dwindle `single_window_aspect_ratio` toggle for this key; it was dropped because it applied only to a lone window and its ratio was hardcoded to 1:1.

Dictation took Insert as push-to-talk — hold to record, release to transcribe — with Shift + Insert latching hands-free recording and a bare Insert press ending the latch; no state is kept, since voxtype ignores a start while already recording and the release's stop ends the latch.
Omarchy's stock F9 was unusable: on this Dell XPS 13 9310 the bare key emits no input event on any device (evtest on every keyboard and hotkey device with keyd stopped), and the firmware's Fn layer offers only whole-row switches (`FnLock`, `FnLockMode`).
Insert's own uses — overwrite mode and a hand-typed Shift + Insert paste — are given up; Omarchy's Super + V sends its Shift + Insert from Hyprland and is unaffected.

The `io.github.poctek.hyprland-submap` widget leaves `omarchy/shell.json`. The `keybindings-menu-submaps` bugfix step stays until upstream #13461 ships; with no submap bindings left it patches a menu that has nothing to group, and it keeps re-applying across `omarchy update` runs until the PR lands.

## Consequences

The "held-modifier keys do navigation only" rule bends for Hyprland: fixed distances and directions now live in chords, recorded in `docs/keybinds.md`'s "Where it bends" rather than by growing a new modal table. tmux's pane table is the only modal table left, so the cross-layer mirror narrows from letters-plus-mechanism to the letters alone.

The panel layer's Ctrl/Alt pair is Hyprland-local and stays out of `docs/keybinds.md` per its upkeep rule; a future letter should take both forms or neither. The wifi toggle speaks nmcli directly, bypassing Omarchy's command surface, so an Omarchy wrapper appearing later should replace it. A full-width maximize is gone: the maximized box is the work area minus `gaps_out`, or `float_gaps` for a floating window (Hyprland 0.56.2 `src/layout/space/Space.cpp`), and `f[1]` sees only the internal fullscreen mode, so two maximize shapes could differ only by floating, which reflowed the tiles on return. Super + Shift + Z fullscreen is the full-width option, covering the bar. The 160-pixel side gap is a fixed number, so another monitor gets another ratio, and one window per workspace can be in zen at a time; focusing another window there drops it (`on_focus_under_fullscreen = 2`).

A stuck mode can no longer strand the keyboard; Escape and Return do nothing special anymore, and the submap-indicator work (widget, menu patch's local half) is retired with the feature.

The suspend binding has not yet been exercised (a real press suspends the machine); the lid, the menu and the key share the same command and ADR-0069's entry-point rule, and `hyprctl binds` verified the registrations.

Not adopted, still reachable from the Omarchy menu and revisitable: calculator, keybindings menus, dictation, bar-panel digits, reminders, transparency and gaps toggles, cursor zoom, width save/restore, monitor scaling.

## Corrections

2026-09-30: the Decision said Super + Escape kept locking. It was bound that way when this record was written and moved to Omarchy's btop on the same day, so the sentence is gone and Ctrl + power is left as the only lock key; the power cluster's other three keys are unchanged.
The Decision's square-aspect toggle was replaced by zen mode, which first landed as a tagged float on Super + Ctrl + Z: floating the window reflowed the others, and freezing them with recorded geometry took about 200 lines of Lua that shelled out to `hyprctl` from inside the compositor, stalling each press about 15 seconds, and sized the window over the gaps. The maximize rule above replaced it; `max_size` on a tagged window, a floating maximize under `float_gaps`, and a renamed-workspace selector were each tried and rejected, and Hyprland's `scrolling` layout is the clean route to a per-column zen if one is ever wanted.
An earlier sentence claiming a `o.bind_toggle` defect upstream was wrong — Omarchy calls the standalone command with `o.bind` — and was removed along with the backlog entry it produced.
