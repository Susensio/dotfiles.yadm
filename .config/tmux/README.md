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

Prefix-bindable floating popup sessions/panes for quick, throwaway work — they pop up over whatever you're doing and close without disturbing the underlying layout.

## Sessionizer

One key (`f`, from the prefix table or the mouse menu) fuzzy-finds a directory and either attaches to a matching existing session or creates a new one for it — a fast way to jump between projects without manually naming/creating sessions.

## Theme & visuals

Gruvbox is the default palette. On Omarchy, tmux follows the active Omarchy theme.
`30_gruvbox.conf` defines Gruvbox colors. `31_palette.conf` maps them to tmux roles, then optionally sources the active palette rendered from `omarchy/themed/tmux-palette.conf.tpl` to override those roles. `32_visual.conf` uses the roles.
The Omarchy theme-set hook reapplies the palette to running main and scratchpad servers after Omarchy's own tmux retint.
Pane borders double as a status signal at a glance: yellow means the pane is in a mode (e.g. copy mode), red means synchronized-panes is on, green means normal.
Window/session activity and bell events are highlighted in the status line, and terminal titles reflect the current tmux position.

### Omarchy's live tmux update

In Omarchy 4.0.4, `omarchy-theme-set` renders the current theme, runs `omarchy-theme-set-foot` and `omarchy-theme-set-tmux` among its live updates, waits for them, then runs `omarchy-hook theme-set`.
Our `theme-set.d/tmux` hook runs at that last step.
Omarchy's tmux updater does the following:

| Update | Purpose and overlap with this config |
| --- | --- |
| `window-style`, `window-active-style` | Recolors tmux panes immediately. `32_visual.conf` sets both again from our palette, preserving its separate inactive style. This can cause a visible intermediate redraw. |
| `FOREGROUND`, `BACKGROUND`, `GUM_*`, `COLORFGBG` | Copies the rendered `gum_env.lua` colors and light/dark indicator into tmux's global and existing session environments for future processes. `gum_env.lua` comes from Omarchy's Gum prompt/menu theme. Already-running shells do not change. Our palette does not replace this. |
| OSC colors to pane TTYs | Sends foreground, background, cursor, selection and ANSI 0–15 colors into each pane. Omarchy separately sends the same palette to running Foot terminals; whether both paths are needed with Foot and tmux is unverified. Our tmux styles do not set the terminal's ANSI palette. |
| `cursor-colour` | Gives tmux a fallback cursor color when an app resets its own cursor color with OSC 112. Our `prompt-cursor-color` applies only to tmux's command prompt. |
| `SIGWINCH`, `refresh-client` | Prompts pane applications and tmux clients to redraw after the live color update. Whether this is needed with our hook is unverified. |

Omarchy 4.0.4 has no switch for only the tmux updater; headless mode skips all live updates and user hooks.
This repo's `environment.d/11_path.conf` puts `~/bin/overrides` ahead of `/usr/bin`, and `profile` imports the user manager's PATH for `bash -lc`.
On the Omarchy machine, check `bash -lc 'type -a omarchy-theme-set-tmux'` before relying on a local wrapper: Omarchy's uwsm and mise setup may alter the effective order.
A wrapper could replace the whole updater without editing Omarchy's package, but would also remove its Gum, `COLORFGBG`, pane OSC, cursor and redraw updates unless supplied elsewhere.
Keep the updater and the hook in place until the live Foot/tmux checks in `docs/STATE.md` settle which updates matter.

## Plugins

Managed with **TPM** (Tmux Plugin Manager), installed automatically if missing.

---

Config is split into `conf.d/*.conf`, loaded in numeric order by `tmux.conf`.
