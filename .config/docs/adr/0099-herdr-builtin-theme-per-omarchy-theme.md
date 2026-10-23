# ADR-0099: Select a Herdr built-in theme per Omarchy theme and write it into the tracked config instead of following the terminal palette or redirecting the config path

Status: Accepted
Date: 2026-10-23

## Context

Herdr 0.9.5 either followed the host terminal's ANSI palette (`terminal`) or used one of 18 built-in themes, and only one of them could follow an Omarchy theme switch.
Helix already preferred its bundled themes: a user Omarchy theme shipped `helix.toml` with `inherits = "gruvbox"`, and Omarchy rendered the generated template only for themes that shipped nothing.
Herdr read its theme only from `[theme] name` in `config.toml`, with no include, theme file, or socket call to set it.
Pointing `HERDR_CONFIG_PATH` at a generated copy would have duplicated the config and required every Herdr process to inherit the variable.
Herdr's own Settings screen changed the theme by rewriting `theme.name` in place, and `herdr server reload-config` made every attached client reload its local config.

## Decision

The Omarchy `theme-set` hook chooses a Herdr theme name and writes it into `[theme] name` of the tracked `config.toml` and `scratchpad.toml`, then reloads each running Herdr session.
A user Omarchy theme names its built-in in a shipped `herdr.theme` file; stock themes, which live under `/usr`, are mapped in the hook; anything else, or a name `herdr config check` rejects, gets `terminal`.
Ask upstream for a theme file with inheritance, which would let the tracked config name a fixed theme like Helix's `omarchy`.

## Consequences

Switching to a theme with a different Herdr built-in marks both Herdr configs as changed alongside `omarchy/theme.name`; they are committed together.
A stock theme whose name matches a Herdr built-in is not assumed to match it: Omarchy's `rose-pine` is light and maps to `rose-pine-dawn`, so new stock themes need a mapping line to get a built-in.
Every reload shows Herdr's "reloaded config" toast.
Editing the theme in Herdr's Settings screen is overwritten at the next Omarchy theme switch.
The `terminal` fallback still needs the hook's SIGWINCH to repaint clients.
