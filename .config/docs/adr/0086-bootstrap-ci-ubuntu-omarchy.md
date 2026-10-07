# ADR-0086: Test the bootstrap from fresh machines in CI, on an Ubuntu runner and an Omarchy container booted into systemd, not a VM or GitHub's container key

Status: Accepted
Date: 2026-10-07

## Context

The bootstrap was a long bet ([principles](../principles.md#bootstrapped)): it paid only when a machine was rebuilt, and nothing exercised it from a fresh state before then, so a rotted step surfaced on the new machine.
The syntax checks in CI caught broken files, not broken steps.

The machines in use were Linux Mint 22 and Omarchy.
An Omarchy VM installed unattended from the ISO was the most faithful option, but needed KVM on the runner, a multi-GB ISO per run and most of the runner's disk, and still booted to a login screen rather than a session.
GitHub's `container:` key kept its own keep-alive process as PID 1, so systemd never ran inside, and every step touching a service needed a guard written only for CI.
A plain Arch container was tried alongside Omarchy and dropped: Omarchy selects the same `distro_family.arch` declarations, so it covered the pacman names, and no plain Arch machine was in use.

Omarchy turned out to be two packages over Arch: `omarchy-settings`, installed before the user so it seeds `/etc/skel`, and `omarchy`, whose provisioning commands were written to run in the ISO's chroot.

## Decision

The Bootstrap workflow runs the README's new-machine steps on every push and pull request, on two fresh machines:

- the `ubuntu-24.04` runner, Mint 22's base, a VM with systemd and a user manager started by lingering;
- an `archlinux` container started with `docker run` and systemd as PID 1, made Omarchy the way its ISO does it from Omarchy's latest release: its pacman configuration and stable mirror, `omarchy-settings`, the ISO's package list and `omarchy`, then `omarchy-apply-system` and `omarchy-provision-user`, with Omarchy's own switches for a root without btrfs and a user without a desktop session.

Making that machine is a local composite action, `.github/actions/omarchy`, so the workflow holds only the dotfiles' own steps.

After the bootstrap the user manager restarts, as the bootstrap asks once environment.d changed, and `just bootstrap-test` checks the machine from a login shell.
The config stays the test's only source of truth: a configured program must start or source its config silently, which it does only when what the config declares is installed, and tools that keep their own record are checked against it.
A second bootstrap must then print nothing.

## Consequences

The generic steps run against `apt` and `pacman` from scratch, the Omarchy step set against a current Omarchy, services included, and the README with them.
Steps that talk to a running desktop (Hyprland, Omarchy's shell) cannot be exercised; they have to tolerate its absence, which also covers bootstrapping over SSH or from a TTY.
Hardware-dependent steps (hibernation, fingerprint readers) only take their absent branch.
The Omarchy job follows Omarchy's installer, so a change in how the ISO installs means a change in the job, and the container runs privileged.
