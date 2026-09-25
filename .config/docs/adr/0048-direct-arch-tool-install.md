# ADR-0048: Install Arch tools directly in tool instead of through mise bootstrap

Status: Accepted
Date: 2026-09-25
Supersedes: [ADR-0046](0046-packages-toml-distro-variants.md)

## Context

ADR-0046 used `mise bootstrap` both to record an Arch package and to install it.
That made `tool install` indirect and left `tool remove` unable to remove the system package it had installed.
The two `packages.toml` variants were still needed: the default variant makes the tool available through mise on non-Arch machines, and the Arch variant recreates its pacman package during bootstrap.

## Decision

The paired `packages.toml` variants remain the record of distro-sourced tools.
On Arch, `tool install` records a newly discovered plain pacman package in both variants and installs it with `sudo pacman -S --needed --noconfirm`.
The bootstrap installs tracked declarations, so `tool install` treats an already declared tool as done.
`tool install --mise` puts a new tool in `tools.toml` even when Arch has a package for it.
`tool remove` removes the corresponding package declared in the Arch variant with `sudo pacman -R --noconfirm` before removing both declarations.
It does not recursively remove dependencies.
On other machines, distro tools continue to install through mise from the default variant.

## Consequences

Interactive tool management has immediate, symmetric system-package effects on Arch and no longer runs mise bootstrap.
Bootstrap still uses the Arch variant for a fresh machine.
The package declaration remains the ownership check, so `tool remove` does not uninstall unrelated pacman packages.
Differently named package pairs use the `pacman` field beside their default mise declaration.
This is a narrow exception to ADR-0044's bootstrap package wrapper because `tool` is already Arch-specific at that branch.
