# ADR-0110: Resolve Helix's Omarchy theme name with a negated distro alternate as the gruvbox fallback

Status: Accepted
Date: 2026-11-10

## Context

Helix selects exactly one theme by name, resolved from a file stem in `themes/`; it has no conditional config, include, or fallback list, and a name that resolves to nothing only logs `failed to load theme` and leaves Helix's built-in default.
The tracked `helix/themes/omarchy.toml` was a symlink into Omarchy's generated state, so on every other machine it dangled and Helix silently stopped being gruvbox.
Tmux faces the same split and keeps a gruvbox default that Omarchy's generated palette overrides ([ADR-0052](0052-direct-omarchy-tmux-palette.md)), but its overrides are separate files sourced in order, which Helix cannot do.
The tracked config already names the fixed theme `omarchy` on the strength of Helix's theme inheritance ([ADR-0099](0099-herdr-builtin-theme-per-omarchy-theme.md)).

Four cheaper-looking mechanisms were rejected.
A plain tracked fallback at `helix/themes/omarchy.toml`, replaced by yadm's `##distro.omarchy` alternate, would be `ln -fs`'d into a symlink on Omarchy, turning a tracked path into a typechange — the reason this repo tracks no plain plus `##` pair.
A bootstrap step creating the link would dirtify the same tracked path and add code where an alternate suffices ([ADR-0080](0080-omarchy-alternate-scope.md)).
Duplicating `config.toml` per distro spends a whole-file alternate on one value ([ADR-0047](0047-helix-canonical-editor-name.md)).
A theme-set hook has nothing to regenerate: the link chain is resolved at read time, and Omarchy rewrites the state file both chains end in.

## Decision

`helix/config.toml` keeps `theme = "omarchy"` on every machine, and that name is resolved by a pair of yadm alternates for the same target file:

- `helix/themes/omarchy.toml##distro.omarchy` is the existing symlink to Omarchy's rendered theme.
- `helix/themes/omarchy.toml##~distro.omarchy` is a theme file inheriting the `gruvbox_transparent` overlay, the previous default.

`yadm alt` materialises the untracked, auto-excluded link `helix/themes/omarchy.toml` to whichever applies, so no tracked path is ever replaced.
No hook is added: yadm's `auto-alt` runs after `clone` and after every git-backed command, and a theme switch only rewrites the state file that the static link already points at.

## Consequences

Non-Omarchy machines get gruvbox under the name `omarchy`; the comment beside the config line and the fallback file's own comment record that the mismatch is deliberate so one fixed name serves both.
A hand-made checkout that never runs yadm sees Helix's warning once and its built-in default, not gruvbox, until `yadm alt` runs; `clone` and bootstrap cover the normal path.
Installing Omarchy onto an already-bootstrapped machine switches the link on the next yadm git command, or an explicit `yadm alt`, rather than on the install itself.
Omarchy's own provisioning of this path (upstream PR #13843) only creates a missing link and therefore coexists: a yadm alt run replaces whichever link is there with the same effective target.
`gruvbox_transparent.toml` stays as the inherited base instead of being folded into the fallback.
