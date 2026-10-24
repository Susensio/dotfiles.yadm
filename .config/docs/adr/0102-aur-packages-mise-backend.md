# ADR-0102: Declare AUR packages through mise's aur backend and check for base-devel, instead of hand-rolled yay calls in bootstrap steps

Status: Accepted
Date: 2026-10-24

## Context

AUR packages arrived here the way ADR-0048 described Arch tools: a bootstrap step shelled out to `yay`.
`wluma.sh` still does (`yay -S --needed --noconfirm wluma`) behind a capability guard, and `docs/omarchy.md` said "mise's `pacman:` backend cannot install AUR packages, which is why it is a bootstrap step".

mise 2026.10.15 has a separate `aur:` backend.
It checks installed state with `pacman -Qm`, installs with `yay -S --aur --noconfirm -- <packages>` (or `paru` when yay is absent), adds `--refresh` on `upgrade`, and refuses to run as root.
`pacman:` remains the sync-repository source: `pacman -Si zapfast-bin` fails on a machine configured with only `core`, `extra`, `multilib` and Omarchy's own repo, while `pacman -Qm` lists it.
A package of the same name in any configured repository does not satisfy an `aur:` entry — status reports it missing and `apply` replaces the repo build with the AUR one — so the two prefixes cannot stand in for each other in either direction.

What the backend does not do decides the shape of the rest.
It supports no version pins (`apply` skips a pinned entry whose version differs), no `state = "absent"` (mise never removes AUR packages), no `import`, and no `prune`.
It also assumes a working AUR toolchain, which mise does not install for it.

Weighed and rejected: keeping `yay` calls in the steps, which leaves every AUR package a special case with its own presence check; declaring AUR packages as `pacman:`, which only appears to work on a machine where `yay` already built them; `aur:yay` beside `pacman:base-devel`, which reads as a bootstrap dependency that mise cannot express, since packages are unordered.

## Decision

An AUR package is a `[bootstrap.packages]` entry `"aur:<pkg>" = "latest"`, and no bootstrap step runs an AUR helper.
`"aur:zapfast-bin"` joins `mise/conf.d/omarchy.toml##distro.omarchy` beside the `pacman:` entries it now sits with as one package list, and `wluma` moves from `wluma.sh` to the same file; that step keeps only what a declaration cannot do.
`yay` and `base-devel` stay the operator's prerequisite: `00_dependencies.sh` checks for them beside what `dependencies.txt` lists, because mise installs neither and an `aur:` entry would otherwise fail on a fresh machine with a helper error rather than a missing prerequisite.

## Consequences

AUR packages lose the per-package presence check and the `--needed` guard; `pacman -Qm` replaces both, and a machine that installed one by hand gets it declared as a no-op.
`yay -S --aur --noconfirm` shows neither the PKGBUILD nor its diff, so reviewing a new or upgraded AUR package is the operator's step, not the bootstrap's — the step it replaces prompted for the same reason.
Dropping the declaration leaves the package installed, and there is nothing to do but `pacman -R`: `absent` is not available, so a removal is not declarative and a bootstrap cannot undo it.
No pin can be carried, so an AUR package the desktop depends on is whatever `yay` builds today.
`mise bootstrap --upgrade` reaches AUR packages through `upgrade` while plain `apply` never updates them, which is the behaviour it already had for `latest` entries on every manager.
`wluma` now installs on every machine this config reaches, since a declaration cannot be conditional; its step still starts it only where an ambient light sensor exists, so a machine without one carries an idle package.
`docs/omarchy.md` names the two prefixes instead of claiming the backend set cannot reach the AUR.
