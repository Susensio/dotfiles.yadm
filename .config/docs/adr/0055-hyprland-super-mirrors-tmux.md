# ADR-0055: Bind the Hyprland desktop on Super with tmux's letters, loading only Omarchy's media and clipboard bindings, instead of Omarchy's default set or a desktop prefix

Status: Accepted
Date: 2026-09-26

## Context

Omarchy 4 shipped a few hundred Hyprland bindings across `default/hypr/bindings/*.lua`, most for apps, panels and toggles that were never used, and its `SUPER + J/K/L` went to split, keybindings and layout.
Alt was already taken inside the terminal: tmux and herdr bound Alt + `hjkl` to panes, `i`/`o` and digits to tabs, `n`/`p` to sessions and agents, and `` ` `` to the scratchpad.
F12 was the terminal prefix, reached as Caps + Space through keyd, and Caps held was Control.
Omarchy offered `omarchy_default_bindings = false`, which skipped every one of its binding files, including volume, brightness, the lid switch, the power button and the keys acting inside the screenshot region picker.
Its menu also searched installed applications, so one key could reach any app.

Weighed and rejected: a Super + Space desktop prefix with one-shot submaps mirroring tmux's key tables, which put too much behind a second keystroke; keeping Omarchy's defaults and unbinding what clashed, which kept most of what was unwanted; a chord per app, when search reached them all.

## Decision

Super drives the desktop the way Alt drives terminal panes, with the same letters: `hjkl` focus, `i`/`o` step through existing workspaces, digits jump and Shift + digit moves the window and follows, `` ` `` is the scratchpad, `q` closes, `z` goes full screen.
Resizing, swapping and moving a workspace between monitors live in one submap, Super + P, mirroring tmux's pane table; it stays active until Escape or Return.
Only four apps get a chord (terminal, browser on `w`, files on `e`, agents on `a`); everything else is searched from the Omarchy menu on Super + Space.
Super + Escape locks, and the power button opens the system menu.
`hypr/hyprland.lua` turns Omarchy's defaults off; `hypr/bindings.lua` requires Omarchy's self-contained `media.lua` and `clipboard.lua` as they are, and copies the lid, power, screenshot and region-picker lines from its `utilities.lua`.

## Consequences

Upstream fixes to the media and clipboard bindings arrive with Omarchy updates; the copied lines do not, and a binding file Omarchy adds later is off until it is required here.
Hyprland shows nothing while a submap is active, so a forgotten window mode turns `hjkl` into resizing until Escape.
`hypr/hyprland.lua` became a tracked copy of Omarchy's seeded template, so a later change to that template reaches the laptop only by hand.
None of this ran against a live Hyprland when written; `docs/STATE.md` carries the checks.
The letters themselves are the live reference's business, not this record's: `docs/keybinds.md` holds the cross-layer scheme, including tmux, herdr and helix's side of it.
