# ADR-0075: Own live tmux retint in the theme-set hook instead of leaving Omarchy's tmux updater enabled

Status: Accepted
Date: 2026-09-29
Supersedes: [ADR-0052](0052-direct-omarchy-tmux-palette.md)

## Context

ADR-0052 left Omarchy's own tmux updater enabled and ran this repo's theme-set hook after it, so a theme switch wrote tmux's colours twice.
Reviewing the updater before the handover showed what each of its writes was for.
Its `window-style` and `window-active-style` writes were overwritten by `32_visual.conf` a moment later, which is a visible intermediate redraw.
It drove plain `tmux` commands, so it reached the current server (`$TMUX`) or `default` only, while the hook had already grown to reload every configured server discovered in the standard socket directory.
Its `cursor-colour` fallback addressed a real foot case: an application's OSC 112 reset otherwise restores the colour of whatever theme was active when foot launched.
Its Gum and `COLORFGBG` values only reach panes started after the switch, since a running shell keeps the environment it was started with.
Its pane-TTY OSC writes and its `SIGWINCH`/`refresh-client` signals were introduced together as "update tmux coloring live" with no consumer recorded, and `omarchy-theme-set-foot` already writes the same palette straight to the outer foot terminal.
Alternatives weighed: keep the updater and add nothing; reimplement it at full width inside the hook; or keep both writers and accept the double write.

## Decision

Disable `omarchy-theme-set-tmux` with a no-op override in `~/bin/overrides`, and let the `theme-set` hook own live tmux retint.
The hook reloads the config on every configured server it discovers — which reapplies the palette, the styles and the cursor colour — and pushes the theme's Gum values and `COLORFGBG` into those servers' global and session environments for future panes.
Cursor colour becomes a palette role like any other: the tracked template renders `CURSOR` from the theme's resolved `cursor`, `31_palette.conf` carries a Gruvbox fallback, and `32_visual.conf` sets `cursor-colour` from it with a runtime format, so a freshly started server is correct without waiting for a theme switch.
The launch-context refusal, keying and cleanup behaviour of the scratchpads are untouched.

## Consequences

One writer now: a theme switch no longer writes pane styles twice, so the intermediate redraw on inactive panes is gone.
The cursor fallback no longer depends on a switch having happened, because it is sourced from the same palette that styles the panes.
The pane-TTY OSC writes and the redraw signals were dropped; no consumer for them was found here and the outer foot is already coloured by Omarchy's own foot updater, so they return only if a live switch shows a missing effect.
The override is reached because `~/bin/overrides` precedes `/usr/bin` on the session `PATH` and Omarchy runs the updater through `bash -lc`; the `hypr-envs-path.sh` bugfix step is what keeps `/usr/share/omarchy/bin` from being prepended.
If either stops holding, the no-op is bypassed silently and both writers return.
Gum values and `COLORFGBG` already reach a freshly started server from the session environment, which loads the theme's `gum_env.lua` at login, so the hook only repairs them after a switch; a session that took a copy at creation is overwritten with it.
`omarchy-theme-refresh` reaches the same no-op, so a manual refresh keeps the contract of a theme set.
Servers outside the standard socket directory — an explicit `-S` path or another `TMUX_TMPDIR` — stay unthemed by the hook.

