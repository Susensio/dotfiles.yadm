# ADR-0044: Gate bootstrap steps on capability instead of distro alternates, and install packages through an own pkg-install instead of pacapt

Status: Accepted
Date: 2026-09-24

## Context

The bootstrap from [ADR-0005](0005-idempotent-directory-dispatched-bootstrap.md) was written for Linux Mint on X11 with LightDM.
Every package step called `apt` directly, and `10_xdg_compliance` installed Xsession.d scripts and a LightDM config unconditionally.
A second machine was planned on Omarchy — Arch, Hyprland under uwsm, SDDM — where the first `apt` call would have aborted the whole run under `set -e`, and the X11/LightDM steps had nothing to patch.

Three ways to make the bootstrap run on both were weighed.
yadm alternates per distro (`##distro.arch`, `##distro.linuxmint`) would have duplicated whole scripts that differed only in their install line.
`##distro_family` was unusable on Mint: yadm 3.5 compared it against the whole `ID_LIKE` string, `ubuntu debian`.
yadm templates varied file contents, not which steps ran.
For package installation, existing distro-agnostic wrappers were considered — pacapt, the most established; sysget, abandoned.
None mapped package names across distros, and any of them had to be fetched before the dependencies it was meant to install.

## Decision

Each bootstrap step checks for the thing it needs, not for a distro name.
Apt repository setup runs only when `apt-get` exists; the Xsession.d install only when `/etc/X11/Xsession.d` exists; the XAuthority redirect only when `lightdm` exists.

System packages go through `~/bin/pkg-install`, a script of our own that uses `pacman` where it exists, else `apt-get`.
It calls plain `pacman` rather than Omarchy's `omarchy-pkg-add`: Omarchy's package routing (its `[omarchy]` repo, its delayed stable Arch mirror) lives in `/etc/pacman.conf`, so any pacman call gets it, and the wrapper added only a post-install check.
Package names pass through unchanged, so a dependency is listed only if its name matches on every distro in use.
`bootstrap` puts `~/bin` on `PATH` for every step, so `pkg-install` and `log` are called by name.

Two fixes landed alongside.
`xdg_compliance` and `fish.sh` were renamed `10_xdg_compliance` and `20_fish.sh`, so the bash dotfiles are moved into `~/.config/bash/` before the fish relay is written.
The relay is now prepended to `bashrc` instead of appended, so bash hands over to fish before a distro's own bashrc exports anything fish would inherit.

## Consequences

One set of scripts serves both machines, and a third distro only needs a branch in `pkg-install` and whatever repository setup it lacks.
Capability checks keep working when the same distro changes session type, which a distro match would not have caught.
Costs: a package whose name differs between distros cannot go in `dependencies.txt` as-is and needs its own step; `pkg-install` is one more script to maintain; and nothing verifies that a gated step is still needed on a machine where it silently skips.
