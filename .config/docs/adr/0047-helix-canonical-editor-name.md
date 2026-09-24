# ADR-0047: Name the editor helix everywhere and let Omarchy's editor menu write EDITOR into tools.conf, instead of hx, an Omarchy-only alternate, a one-off seed, or a local override

Status: Accepted
Date: 2026-09-24

## Context

[ADR-0008](0008-replace-neovim-with-helix.md) pointed `EDITOR` and `SUDO_EDITOR` at `hx`, the binary name in upstream's release tarball, which mise installed.
[ADR-0046](0046-packages-toml-distro-variants.md) then sourced helix from pacman on Arch, where the binary was named `helix`, and a bootstrap hook linked `~/.local/bin/hx` to it.
On Omarchy that name mattered beyond the shell: `omarchy-restart-helix` signalled `pkill -USR1 helix` on every theme change, and a process started through a link named `hx` was named `hx`, so the signal missed it.

Omarchy kept its own editor choice, written by its default-editor menu to `~/.local/state/omarchy/defaults/editor` and read by `omarchy-launch-editor`, which its menus called directly; with no choice made, the launcher used `nvim`.
Its uwsm session also exported `EDITOR="omarchy-launch-editor --inline"`.
So `$EDITOR` readers (git, `sudoedit`, lazygit) and Omarchy's menus could open different editors.

Several ways to reconcile them were weighed and rejected.
Picking helix in the menu by hand on every machine was a manual step.
Seeding Omarchy's choice once at bootstrap let a later menu pick drift from `EDITOR`.
A yadm class alternate, `environment.d/editor.conf##class.omarchy` set to Omarchy's launcher, made a whole alternate file for one variable.
An untracked `environment.d` file written by a watcher and sorted after `tools.conf` kept the pick off the tracked setting.

`sudoedit` complicated a bare editor name.
In sudo 1.9.15 it looked a bare `SUDO_EDITOR`, `VISUAL` or `EDITOR` up in `secure_path`, not the user's `PATH`, fell back to the system editor (nano on Mint) when that failed, and then ran the editor it found with the user's unmodified environment.
Helix from mise lived in `~/.local/bin`, outside `secure_path`.
An absolute path differed per machine; a link into `/usr/local/bin`, a sudoers `editor` default, adding `~/.local/bin` to `secure_path`, and a `sudoedit` wrapper in `~/bin/overrides` were all rejected.

## Decision

`helix` is the editor's name everywhere: `EDITOR=helix` in `environment.d/tools.conf`, and `SUDO_EDITOR="env $EDITOR"` below it, which `sudoedit` finds as `/usr/bin/env` and which then finds the editor on the user's `PATH`.
Arch dropped its `hx` link hook.
Where mise installs helix, a `postinstall` on the tool in `packages.toml##default` links `helix` to `hx` inside the install directory, so it is recreated on every upgrade, and `system-install` links it into `~/.local/bin`.
Fish expands `h` and `hx` to `helix`, and the `ctrl-g` binding matches either name.

On Omarchy, Omarchy's menu is a front end for the tracked `EDITOR`.
A bootstrap step, `omarchy/editor.sh` and gated on `omarchy-default-editor` existing, generates a systemd user path unit that watches Omarchy's choice and runs the same script's `sync` mode, which rewrites the `EDITOR=` line in `tools.conf`; `SUDO_EDITOR` follows through `$EDITOR`.
The sync is a mode of the bootstrap step rather than a command in `~/bin`, so it sits on no machine's `PATH`, and rather than a sibling executable, which the bootstrap would run as a step of its own.
Omarchy-only steps each get their own file under `bootstrap.d/omarchy/`.
Only terminal editors are copied; a GUI pick leaves the previous value.
On a fresh install the same step seeds Omarchy's choice from the `EDITOR=` line in `tools.conf`, not the live `$EDITOR`, which in an Omarchy session was uwsm's launcher.

## Consequences

Helix started through `EDITOR` or the abbreviations is a process named `helix`, which Omarchy's reload signal and launcher expect.
Changing editor on Omarchy is one menu pick, which lands as a yadm diff to `tools.conf` and, once committed, reaches every machine; elsewhere it is an edit to the same line.
Costs: `hx` is only an abbreviation on Arch, so anything outside interactive fish that calls `hx` fails there; the sync runs a `daemon-reload` but, like any `environment.d` change, reaches running shells only through `env_reload`; which of uwsm's session `EDITOR` and `environment.d`'s wins was left open, though once the two agree it no longer changes which editor opens; and the sync relies on Omarchy's state file path and its list of terminal editors, both internal to Omarchy.
