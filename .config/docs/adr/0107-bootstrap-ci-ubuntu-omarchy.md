# ADR-0107: Test the bootstrap from fresh machines in CI, on an Ubuntu runner, a bare Debian container and an Omarchy container booted into systemd, not a VM

Status: Accepted
Date: 2026-10-07

## Context

The bootstrap was a long bet ([principles](../principles.md#bootstrapped)): it paid only when a machine was rebuilt, and nothing exercised it from a fresh state before then, so a rotted step surfaced on the new machine.
The syntax checks in CI caught broken files, not broken steps.

The machines in use were Linux Mint 22, Omarchy and Debian 13.
An Omarchy VM installed unattended from the ISO was the most faithful option, but needed KVM on the runner, a multi-GB ISO per run and most of the runner's disk, and still booted to a login screen rather than a session.
GitHub's `container:` key kept its own keep-alive process as PID 1, so systemd never ran inside, and every step touching a service needed a guard.
A plain Arch container was tried alongside Omarchy and dropped: Omarchy selects the same `distro_family.arch` declarations, so it covered the pacman names, and no plain Arch machine was in use.

Debian 13 differs from Mint 22 where Ubuntu's answers did not carry over: a different repository for fish, no PPA for keyd, no `acl`, and a bare install without sudo, curl or git, which the Ubuntu runner has from the start.
Those failed only on a real Debian machine.
Debian's services (keyd's and the user units) are also on the other two jobs, so a plain `debian:13` container reached by the `container:` key covers its packages and repositories, and the Omarchy job stays the one that runs systemd.
The guard it needs is not written for CI: the steps that talk to systemd already tested for it implicitly, and now ask whether it runs, which also lets the bootstrap finish in any container.

Omarchy turned out to be two packages over Arch: `omarchy-settings`, installed before the user so it seeds `/etc/skel`, and `omarchy`, whose provisioning commands were written to run in the ISO's chroot.

## Decision

The Bootstrap workflow runs the README's new-machine steps on every push and pull request, on three fresh machines:

- the `ubuntu-24.04` runner, Mint 22's base, a VM with systemd and a user manager started by lingering;
- a `debian:13` container from the bare image, where the job installs only sudo, wget and a user, as a Debian install leaves one who can sudo, and the job runs the same `source <(curl -fsSL .../.config/yadm/new-machine)` the README gives, with environment overrides for this branch;
- an `archlinux` container started with `docker run` and systemd as PID 1, made Omarchy the way its ISO does it from Omarchy's latest release: its pacman configuration and stable mirror, `omarchy-settings`, the ISO's package list and `omarchy`, then `omarchy-apply-system` and `omarchy-provision-user`, with Omarchy's own switches for a root without btrfs and a user without a desktop session.

Making that machine is a local composite action, `.github/actions/omarchy`, so the workflow holds only the dotfiles' own steps.

After the bootstrap the user manager restarts (the Debian container has none, so its test applies the PATH of `environment.d` by hand), as the bootstrap asks once environment.d changed, and `just bootstrap-test` checks the machine from a login shell.
The config stays the test's only source of truth: a configured program must start or source its config silently, which it does only when what the config declares is installed, and tools that keep their own record are checked against it.
A second bootstrap must then print nothing.

## Consequences

The generic steps run against `apt` (twice, on two repository layouts) and `pacman` from scratch, the Omarchy step set against a current Omarchy, services included, and the README with them.
Services are exercised on Ubuntu and Omarchy but not on Debian, whose container skips keyd's service, its user sync and mise's services; `bootstrap-test` skips their checks the same way.
All three jobs source `new-machine` from the branch under test, so the CI also exercises the README entry point; `NEW_MACHINE_BRANCH`, `NEW_MACHINE_REPO_URL` and `NEW_MACHINE_RAW_URL` override the defaults without changing what a real user runs.
Steps that talk to a running desktop (Hyprland, Omarchy's shell) cannot be exercised; they have to tolerate its absence, which also covers bootstrapping over SSH or from a TTY.
Hardware-dependent steps (hibernation, fingerprint readers) only take their absent branch.
The Omarchy job follows Omarchy's installer, so a change in how the ISO installs means a change in the job, and the container runs privileged.
