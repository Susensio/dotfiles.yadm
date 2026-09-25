# ADR-0052: Source Omarchy's generated tmux palette directly instead of using yadm alternates or symlinks

Status: Accepted
Date: 2026-09-25

## Context

Tmux had a detailed Gruvbox palette, while Omarchy 4.0.4 changed its own theme and then reset tmux's window styles.
The dotfiles needed Gruvbox on other distros and the active Omarchy palette on Omarchy, including at tmux startup.
Yadm templates were generated only when `yadm alt` ran, not on every Omarchy theme change.
An Omarchy generated palette loaded through a nested `source-file` left parse-time `$COLOR` substitutions in the visual config at Gruvbox values during startup.

## Decision

Keep Gruvbox's raw colors in its own file and let Omarchy render a tracked template into its ignored current-theme state.
Map Gruvbox colors to tmux roles in `31_palette.conf`, then optionally source Omarchy's generated file at the end of that file to override the roles directly.
Resolve roles in `32_visual.conf` with tmux formats.
Run a user theme-set hook after Omarchy's own tmux retint to reapply the palette and visuals to running servers.
Do not use a yadm alternate, generated symlink, or yadm template for the active palette.

## Consequences

On a distro without Omarchy's generated file, tmux kept the Gruvbox roles without a broken symlink or per-distro setup.
On Omarchy, changing the theme regenerated the palette and the hook restored this layout's styles after Omarchy's updates, while leaving its pane terminal and cursor updates in place.
The Omarchy override needed to set tmux roles itself: parse-time `$VAR` substitutions in the visual config did not reliably see values from a nested source during startup.
Visual styles use runtime `#{ROLE}` formats or `set -F` so they see whichever role values were last assigned.
Changing a shared role now requires updating the Gruvbox mapping and Omarchy template, while their native color names stay independent.
