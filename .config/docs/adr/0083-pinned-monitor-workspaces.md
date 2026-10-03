# ADR-0083: Pin workspaces to the main monitor and keep a fixed side workspace

Status: Accepted
Date: 2026-10-03

## Context

The dock added a portrait monitor beside the main 4K one.
Hyprland's workspaces are global: an empty workspace opens on the focused monitor and one with windows stays where it was created, so the same digit landed on either screen.
Omarchy's workspace bar widget highlights the globally focused workspace on every screen's bar, so the side screen's bar always showed the main screen's number.
The alternatives were global workspaces as shipped, numbered ranges per monitor, a per-monitor numbering plugin (`split-monitor-workspaces`, `hyprsplit`), and one fixed workspace on the side screen.
hyprmoncfg already managed the monitor profiles, and its first workspace rules were hand-written into its generated file, which the next apply rewrites; it had also imported the zen-mode `f[1]` selector as if it were a workspace.

## Decision

In the dock profile, hyprmoncfg pins workspaces 1–9 to the main monitor and workspace 10 to the side monitor, matched by monitor description, with no persistent workspaces.
Super + 0 selects workspace 10 and Super + Shift + 0 sends a window there; Super + Shift + Alt + hjkl moves the current workspace to a monitor, in the ADR-0076 chord family.
The profiles are the tracked source; the generated monitor file is ignored.
The side screen keeps the stock Omarchy bar.

## Consequences

Super + digit always lands on the same screen, and the side screen changes only on Super + 0 or an explicit move.
A workspace moved by hand returns to its pinned monitor when it is next created.
Accepted: the side screen's bar still highlights the main screen's workspace.
Hiding it needs a cloned `omarchy.bar` filtering its screens, which was tried and dropped to avoid maintaining a fork of the bar; Omarchy has no per-screen bar setting and Hyprland's layer rules cannot hide one screen's surface, so an upstream bar option is the way back to it.
Accepted: hyprmoncfg's workspace rules carry no `default`, so after a hotplug or login the side screen may open on another number until Super + 0.
