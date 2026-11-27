# ADR-0138: Name single-theme tools' theme follow and pick Omarchy's or a fallback with a distro alternate pair, not an Omarchy-named stand-in, an extension or a settings alternate

Status: Accepted
Date: 2026-11-27

## Context

Claude, Helix and pi each select one theme by a name in a tracked config file, with no fallback list, and Omarchy renders a theme for each of them into its generated state.
tmux layers a gruvbox default under an optional sourced override ([ADR-0052](0052-direct-omarchy-tmux-palette.md), [ADR-0075](0075-omit-omarchy-tmux-updater.md)), so it needed none of this.
[ADR-0110](0110-helix-theme-fallback.md) gave Helix a distro alternate pair under the name `omarchy`, and the same shape was wanted for the other two; Claude's `custom:omarchy` and pi's `omarchy-system` resolved to nothing on a machine without Omarchy, and pi printed a startup error for it before falling back to its `system` theme.

What each tool allows, as tested on 2026-11-25 to 27:

- Claude: `theme` takes a built-in name or `custom:<file stem>`; a custom theme exists only as a file in its `themes/` directory, extends nothing but a built-in `base`, and has no inline form. The string a plugin-shipped theme is stored under is undocumented. A per-machine value would need a whole-file alternate of `settings.json`, a root-owned managed-settings file, or a template processor this machine lacks.
- Helix: a theme file can `inherits` another, so its fallback is two lines.
- pi: a theme is found by file name, a link to a different file passes, and a second file with the same inner name as Omarchy's copy raises a `[Theme conflicts]` banner unless it is a link to that same file. `ctx.ui.setTheme("<name>")` from an extension persists the name into `settings.json`; passing the theme object does not. `omarchy-theme-set-pi --activate` writes it there too, and pi already rewrites that tracked file with its own version counters.
- Omarchy writes the Claude and pi theme files itself (`claude/themes/omarchy.json`, `pi/agent/themes/omarchy-system.json`), the latter under a name hardcoded in its script.

Rejected: keeping the `omarchy` name on a gruvbox stand-in (misleading off Omarchy); a pi extension choosing the theme at session start (a hidden override of a setting, code for a colour); `--activate` or a settings alternate (a machine-specific value in a tracked file); a static gruvbox everywhere (loses the live Omarchy theme); a root-owned managed-settings file for a cosmetic preference.

## Decision

Each of the three tools names its theme `follow` in the tracked config, and a pair of yadm alternates ([ADR-0080](0080-omarchy-alternate-scope.md)) decides what that name is:

- `<tool>/themes/follow.<ext>##distro.omarchy` is a link to the Omarchy theme file: Helix's rendered `helix.toml`, Claude's rendered `claude.json`, and for pi `omarchy-system.json` beside it, the file Omarchy's own script keeps current.
- `<tool>/themes/follow.<ext>##~distro.omarchy` is the fallback: Helix inherits `gruvbox_transparent`; Claude links the `claude-themes` marketplace plugin's `gruvbox-dark-ansi.json`; pi links its own stock `dark.json` through the mise `latest` path.
- The materialised link is untracked, as ADR-0110 prescribes, and so are the files Omarchy writes.

Omarchy's Claude theme renders with an ANSI base from a local override of its template (`omarchy/themed/claude.json.tpl`), so code blocks follow the terminal palette instead of Monokai; `maintenance` reports when Omarchy's stock template changes under that override, as it does for every override in `omarchy/themed/`.

## Consequences

The name says what it does on every machine, and `ls -l` on the tool's `themes/` directory shows which side applies.
No tool carries a machine-specific value in a tracked file, and nothing runs at session start.

The fallbacks are uneven: Helix's is gruvbox, Claude's is gruvbox ANSI and looks right only where the terminal runs a gruvbox palette, and pi's is pi's stock dark, since pi has no gruvbox or terminal-palette theme file to link to.
The Claude fallback is a link into the plugin's marketplace checkout, so `gruvbox@claude-themes` must stay enabled and the checkout must exist, and the pi fallback dangles where pi is not installed through mise; neither has run on a machine without Omarchy.
The pi name `omarchy-system` stays in Omarchy's script and in the `omarchy/themed/pi.json.tpl` override, because renaming the file it writes would collide with the link.
The Claude template override is a snapshot of Omarchy's, kept honest only by the `maintenance` check.

## Corrections

2026-11-27: the pi theme's inner `name` is `follow`, set in the `omarchy/themed/pi.json.tpl` override, not `omarchy-system` as the last Consequences paragraph says.
The `/settings` picker lists and checks a theme by that inner name, so with `omarchy-system` inside it showed `system` as the current theme although the Omarchy palette was applied; with `follow` inside it checks `follow`.
`follow.json` links to Omarchy's `omarchy-system.json`, so the two paths are one file and raise no conflict; only the file Omarchy's script writes keeps its fixed name.

2026-11-27: the fallbacks ran on `nuc`: Claude showed the gruvbox custom theme and pi started without the theme error, so the last Consequences paragraph's "has not run" no longer holds.
One quirk was accepted there: pi's `/settings` picker checks `system` instead of `follow`, because the fallback link keeps the stock `dark.json`'s inner name `dark` and the picker matches the setting against inner names; the applied theme is the link's target.
Pi's theme schema has no `inherits` or alias, so only a file whose inner name is `follow` would fix it: a tracked copy, or one generated by a bootstrap step from a community gruvbox package (`hasit/pi-community-themes`, pinned tag); both were left undone as costing more than a menu label.
