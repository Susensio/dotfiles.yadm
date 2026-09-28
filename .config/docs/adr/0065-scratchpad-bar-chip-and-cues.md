# ADR-0065: Mark the Hyprland scratchpad with its own bar chip and Hyprland cues, instead of forking the workspaces widget

Status: Accepted
Date: 2026-09-28

## Context

Nothing on screen said the scratchpad was up. The bar's `omarchy.workspaces` widget marks the workspace underneath a special workspace as focused, and that is not a widget defect: with the scratchpad shown, Hyprland's `activeworkspace` still reports the covered workspace, and the shell's Hyprland model carries no special-workspace property, so the widget has nothing to read. The only cue was Hyprland's background dim at its default `decoration:dim_special` of 0.2, and the scratchpad's own window covers nearly all of it.

Alternatives weighed:

- Fork the widget (`omarchy plugin clone omarchy.workspaces`, Omarchy's own route for changing how workspace labels render) and give it a scratchpad chip plus a focus rule that ignores the covered workspace. Rejected: it drops tracking of a first-party widget for a cosmetic gain.
- Hyprland-level cues only. Rejected: nothing in the bar would name the scratchpad.
- A community plugin for the chip. Rejected: a third-party extension to track for something this small, and it cannot see special-workspace visibility either.
- A widget of our own for the chip, next to the untouched workspaces widget.

## Decision

A user-owned bar widget, `susensio.scratchpad`, sits directly after `omarchy.workspaces`, one `omarchy.spacer` apart so it reads as its own group rather than another workspace number: dim while the scratchpad is empty, foreground while it holds windows, the theme accent while it is on screen, and a click toggles the scratchpad. It follows the bar's existing plugin contract and file layout rather than forking or patching a first-party widget.

Visibility cannot come from the shell's Hyprland model, so it comes from the `activespecial` Hyprland event, seeded once at startup from a bounded `hyprctl monitors` query. The event is not part of the shell's Hyprland model either, but raw events reach widgets, as the submap indicator already relies on.

Hyprland adds two cues, both from user config: windows on `special:scratchpad` carry a border twice the weight of a tiled window's, and `decoration:dim_special` rises from 0.2 to 0.5 so the covered workspace reads as behind.

Two details carry their reasons:

- The chip does not reuse the workspaces widget's focus glyph for the on-screen state. Hyprland reports the covered workspace as active, so the bar already paints that glyph on the workspace underneath; a second one reads as a second focused workspace. The accent marks the overlay instead, matching the scratchpad window's own border.
- The border keeps the active (accent) colour rather than a foreign hue. Measured across the 22 stock themes and this one, a fixed hue collides silently with themes whose accent sits nearby, and the accent cannot collide with itself. The width carries the difference.

## Consequences

The bar's workspace strip still shows the workspace under the scratchpad as focused, because that is what Hyprland reports; only a change to the workspaces widget closes that gap, which makes asking upstream the one clean way out.

The three chip states are distinguishable on gruvbox by measurement: `#EBDBB2` (foreground) with windows, `#FE8019` (accent) while on screen, and `#AEA49B` when empty, the stock dimmed treatment.

`dim_special` dims the rest of the screen for any open special workspace, not only the scratchpad; at 0.5 a covered pixel measures `#27282A` → `#141415`.

The chip is ours to keep working. An edited plugin QML did not take effect on the documented reload path — a full `omarchy restart shell` was needed, not `omarchy-shell shell rescanPlugins`.

A shell restart is also how a chip edit is seen at all, which is the reason the plugin stays small: one workspace out of `Hyprland.workspaces`, one event, one `hyprctl` seed.

Marketplace plugins are git clones under `~/.config/omarchy/plugins/` and stay untracked in yadm, so a fresh machine has to reinstall them; this chip is plain files rather than a clone, so the config carries it. Its `shell.json` entry and the files have to move together.
