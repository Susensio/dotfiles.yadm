# tmux config — quick overview

## Prefix & navigation

The prefix is `F12`, not the default `C-b` — bound to capslock-space via keyd, kept distinct from a real `C-Space` press.
From there, keys branch into modal sub-tables instead of one flat prefix map:

- `p` → pane actions, `t` → tab (window) actions, `s` → session actions, `c` → config actions (e.g. `r` reloads the config).
- Each table pops a **which-key** hint menu listing its bindings if you pause for a moment instead of pressing the next key immediately.
- A few things sit directly under the prefix itself: `Enter` (new split), `v` (enter copy mode), `:` (command prompt), `f` (sessionizer), `g` (lazygit).
- Pane/window/session switching also has direct, no-prefix bindings (e.g. vim-style directional keys) with boundary guards so they don't wrap past the edge pane.

## Copy mode

Copy mode uses tmux's native vi selection model, so `w`, `b`, `e` and their WORD variants use tmux's own boundaries.
`v` starts a selection, `x` selects lines, `C` starts rectangle selection, and `y`/`Y` copy the selection/current line.
`mi<obj>` and `ma<obj>` select inner or around text objects; `mm` and `%` jump to a matching bracket.
`_` intentionally has no trim-selection binding because tmux cannot change a live selection's whitespace endpoints.

## Mouse

Click-drag selects and copies text; releasing the drag copies automatically.
Right-click opens a context menu (rename, kill, switch session, etc.) built from scratch since tmux ships none by default.
Pane borders show small clickable `[z]`/`[x]` buttons (zoom/close), and the scroll wheel enters copy mode — except inside fullscreen apps like `less` or `vim`, where it passes through untouched.

## Scratchpads

Prefix-bindable floating panes for quick, throwaway work — they pop up over whatever you're doing and close without disturbing the underlying layout.
Their limits on the installed tmux version (per-window scope, border style, 3.9 changes) are in [`docs/tmux.md`](../docs/tmux.md).

## Sessionizer

One key (`f`, from the prefix table or the mouse menu) fuzzy-finds a directory and either attaches to a matching existing session or creates a new one for it — a fast way to jump between projects without manually naming/creating sessions.

## Theme & visuals

Gruvbox is the default palette. On Omarchy, tmux follows the active Omarchy theme.
`30_gruvbox.conf` defines Gruvbox colors. `31_palette.conf` maps them to tmux roles, then optionally sources the active palette rendered from `omarchy/themed/tmux-palette.conf.tpl` to override those roles. `32_visual.conf` uses the roles.
The Omarchy theme-set hook scans the standard tmux socket directory and reapplies the palette, styles and cursor colour to every running server that loaded this config, including native scratchpads but not Herdr's bare shim.
Omarchy's own tmux updater is disabled by a no-op override in `~/bin/overrides` ([ADR-0075](../docs/adr/0075-omit-omarchy-tmux-updater.md)), so the hook is the only writer.
Pane borders double as a status signal at a glance: yellow means the pane is in a mode (e.g. copy mode), red means synchronized-panes is on, green means normal.
Window/session activity and bell events are highlighted in the status line, and terminal titles reflect the current tmux position.

### Live theme updates

A theme switch retints every running tmux server through the `theme-set` hook, which replaces Omarchy's own tmux updater ([ADR-0075](../docs/adr/0075-omit-omarchy-tmux-updater.md); the override's `PATH` reach is in [`docs/omarchy.md`](../docs/omarchy.md)).
If a live switch in foot shows a missed colour or a stale pane, start with the ADR's dropped OSC and redraw writes.

## Plugins

Managed with **TPM** (Tmux Plugin Manager), installed automatically if missing.

---

Config is split into `conf.d/*.conf`, loaded in numeric order by `tmux.conf`.
