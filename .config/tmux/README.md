# tmux config — quick overview

## Prefix & navigation

The prefix is `C-Space`, not the default `C-b`. From there, keys branch into
modal sub-tables instead of one flat prefix map:

- `p` → pane actions, `t` → tab (window) actions, `s` → session actions,
  `c` → config actions (e.g. `r` reloads the config).
- Each table pops a **which-key** hint menu listing its bindings if you
  pause for a moment instead of pressing the next key immediately.
- A few things sit directly under the prefix itself: `Enter` (new split),
  `v` (enter copy mode), `:` (command prompt), `f` (sessionizer), `g`
  (lazygit).
- Pane/window/session switching also has direct, no-prefix bindings (e.g.
  vim-style directional keys) with boundary guards so they don't wrap past
  the edge pane.

## Copy mode

Copy mode supports two selectable motion grammars, not just stock tmux's
vi-mode: **vim** (operator-then-motion, e.g. `dw`, `ciw`) or **Helix**
(selection-first, e.g. select a word then act on it). Pick one via
`@copy_profile` in `conf.d/21_copy.conf`; everything past the profile
switch (search, yank/paste, text objects) is shared by both.

## Mouse

Click-drag selects and copies text; releasing the drag copies automatically.
Right-click opens a context menu (rename, kill, switch session, etc.) built
from scratch since tmux ships none by default. Pane borders show small
clickable `[z]`/`[x]` buttons (zoom/close), and the scroll wheel enters copy
mode — except inside fullscreen apps like `less` or `vim`, where it passes
through untouched.

## Scratchpads

Prefix-bindable floating popup sessions/panes for quick, throwaway work —
they pop up over whatever you're doing and close without disturbing the
underlying layout.

## Sessionizer

One key (`f`, from the prefix table or the mouse menu) fuzzy-finds a
directory and either attaches to a matching existing session or creates a
new one for it — a fast way to jump between projects without manually
naming/creating sessions.

## Theme & visuals

Gruvbox color scheme throughout. Pane borders double as a status signal at a
glance: yellow means the pane is in a mode (e.g. copy mode), red means
synchronized-panes is on, green means normal. Window/session activity and
bell events are highlighted in the status line, and terminal titles reflect
the current tmux position.

## Plugins

Managed with **TPM** (Tmux Plugin Manager), installed automatically if
missing.

---

Config is split into `conf.d/*.conf`, loaded in numeric order by
`tmux.conf`.
