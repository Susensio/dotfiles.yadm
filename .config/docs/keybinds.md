# Keybinds

The same letters mean the same thing at every layer, one modifier up each time: Control moves inside an editor, Alt moves inside a terminal multiplexer, Super moves the desktop.
Letters learned once in tmux transfer to herdr, to Hyprland, and back.
[ADR-0055](adr/0055-hyprland-super-mirrors-tmux.md) records why the Super layer copies tmux's letters instead of adopting Omarchy's defaults; this file is the live reference for what the letters are.
A config comment re-teaching the scheme is a smell: point here instead and say nothing.

## Hardware (keyd)

keyd (`keyd/default.conf`) sets the floor every layer stands on.
Caps is Escape on tap and Control on hold.
Caps + Space sends F12, which is the prefix key for tmux and herdr, so the prefix is reachable without leaving home row.
Pressing both Shift keys toggles Caps Lock.

## Layers

| Layer | Modifier | Scope | Config |
|---|---|---|---|
| Editor | Control | helix's own splits | `helix/config.toml` |
| Multiplexer | Alt | tmux panes and windows, herdr panes and tabs | `tmux/conf.d/20_keybinds.conf`, `herdr/config.toml` |
| Desktop | Super | Hyprland windows and workspaces | `hypr/bindings.lua` |
| Modal tables | prefix, mode, or submap | resize, swap, close | see below |

Held-modifier keys do navigation only.
Anything with an argument — close confirmations, resize distances — lives in a modal table, entered with one key and left with Escape or Return.
Hyprland is the exception since [ADR-0076](adr/0076-hyprland-chords.md): its window actions are chords, one modifier per action with a fixed distance or direction, so no mode can be left stuck.

nvim exists as a fallback editor with its own leader and none of these letters; it does not participate in the scheme.

## Held-modifier letters

| Key | tmux (Alt) | herdr (Alt) | Hyprland (Super) |
|---|---|---|---|
| h j k l | focus pane | focus pane | focus window |
| Ctrl + hjkl | – | – | resize window (repeatable) |
| Shift + hjkl | – | – | swap window |
| Alt + hjkl | – | – | move window to monitor |
| Shift + Alt + hjkl | – | – | move workspace to monitor |
| i / o | previous / next window | previous / next tab | previous / next workspace |
| 1–9 | select window | select tab | select workspace |
| Shift + 1–9 | – | – | move window to workspace |
| ` | scratchpad popup | scratchpad popup | toggle scratchpad workspace |
| m | man popup | man popup | – |
| n / p | next / previous session | next / previous agent | – |

tmux and herdr guard their pane focus at edges (tmux with `pane_at_*` conditions); Hyprland's focus crosses monitors instead of stopping at edges.

## Prefix (F12 = Caps + Space)

herdr's stock keymap differs from tmux's (close pane on prefix+x, detach on prefix+q, copy mode on prefix+[).
`herdr/config.toml` rebinds it to tmux's alphabet; the shared rows below are that file's doing, and an `omarchy update` migration reseeding `herdr/config.toml` would undo them.
herdr adopted tmux's table letters per [ADR-0012](adr/0012-modal-tmux-key-tables.md).

| Key | tmux | herdr |
|---|---|---|
| Enter | new split | smart split |
| t | new window | new tab |
| r | rename window | rename tab |
| v | copy mode (helix motions, [ADR-0014](adr/0014-keep-vim-and-helix-copy-mode.md)) | copy mode |
| f | sessionizer | sessionizer |
| g | lazygit | lazygit |
| d | detach | detach |
| C | config table | settings |
| R | reload config | reload config |
| P / p | pane table (P) | resize mode (p) |
| T | tab table | – |
| S | session table | – |

Each tool binds more beyond these; the config is the list.
tmux's pane table (Prefix P) holds close (q), zoom (z), resize (hjkl, repeatable) and swap (Shift + hjkl); its tab and session tables hold new (n), close (q) and rename (r) for their level, and the config table holds reload, edit and toggles.

## Modal tables

| Mechanism | Enter | Holds | Leave |
|---|---|---|---|
| tmux key tables ([ADR-0012](adr/0012-modal-tmux-key-tables.md)) | Prefix, then P / T / S / C | pane, tab, session, config operations | action exits; which-key menu arms the table |
| herdr resize mode | Prefix p | pane resize | a mode bar replaces the tab bar while active |
| helix select mode | v | selection operations | Escape |

Hyprland left the modal tables when its window actions moved to chords ([ADR-0076](adr/0076-hyprland-chords.md)); tmux's four tables and herdr's resize mode remain.

## Where it bends

- tmux confirms destructive closes with `confirm-before`; Hyprland's Super + q and herdr's close have no confirmation.
- herdr's close tab sits on Shift + q because q alone closes a pane; tmux keeps close inside its pane and tab tables.
- Alt + ` popups float over the terminal; Hyprland's scratchpad is a special workspace, and Shift + ` moves the focused window into it without following.
- Inside the Herdr scratchpad, F12 + v scrolls and Alt + ` detaches; layout-creation keys are disabled because the popup is one shell, not another workspace.
- Helix navigates its splits with Control + hjkl because Alt + hjkl is owned by the multiplexer wrapping it; its buffer stepping (gn / gp) is layer-local and stays out of the tables.
- Hyprland's digits are keycodes (`code:10` and up), not symbols, so workspace keys survive keyboard-layout changes; tmux and herdr use plain Alt digits.
- Alt + n / Alt + p mean "next / previous sibling" in each tool's own dimension: tmux sessions, herdr agents. Hyprland has no session dimension; it cycles windows with Super + Tab instead.
- Hyprland's window actions are chords, not a modal table: Ctrl + hjkl resizes, Shift + hjkl swaps, Alt + hjkl sends the window to a monitor. tmux keeps its pane table, so the hjkl letters mirror across layers while the mechanism no longer does.
- The prefix is F12, not an Alt chord, so it works identically inside and outside tmux, and herdr's prefix never collides with the shell's Alt usage.
- herdr's stock resize mode lives on prefix+r; `config.toml` moves it to p, the letter of tmux's pane table, which tmux reaches as capital P like its other tables.

## Upkeep

A new binding that crosses layers gets its letter here first, then the configs.
Layer-local bindings stay out of this file.
When a mirror breaks on purpose, add a line to "Where it bends" rather than a comment at the binding.
