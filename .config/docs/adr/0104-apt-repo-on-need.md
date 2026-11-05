# ADR-0104: Add an apt repository only where apt lacks the package, or by distro name where upstream publishes per distro

Status: Accepted
Date: 2026-11-05

## Context

The fish and keyd bootstrap steps added an Ubuntu PPA on every machine with `apt-get`, which [ADR-0044](0044-gate-bootstrap-on-capability.md) had treated as the capability for apt repository setup.
A Debian 13 server broke that: Debian has no `add-apt-repository`, and Ubuntu PPAs do not target it.
extrepo, already used for mise, had no entry for either package.

The two packages needed different things.
Debian 13 packaged keyd but Ubuntu 24.04, Mint 22's base, did not; the PPA was only ever there to supply a missing package.
Debian 13 packaged fish 4.0.2 while upstream was at 4.9, and the newer series was wanted everywhere.
Upstream published fish 4.x per distro: an openSUSE Build Service (OBS) project with builds for Debian releases, and a PPA for Ubuntu.

Probing OBS for a build named after `ID` and `VERSION_ID`, falling back to the PPA, was tried as a capability check.
It still keyed on the distro name, only less visibly, and read worse than a plain `case`.

## Decision

A step adds a third-party apt repository only when the machine needs it.

- When the repository only supplies a package the distro lacks, the step asks apt first: keyd's PPA is added only when `apt-cache policy keyd` has no candidate after an update.
- When the repository is wanted for a newer version and upstream publishes per distro, the step branches on `ID` from `os-release`, an exception to ADR-0044: fish uses the PPA on `ubuntu` and `linuxmint`, and the OBS repository for `Debian_<VERSION_ID>` on `debian`.

## Consequences

Debian gets keyd from Debian and fish from OBS, and Ubuntu and Mint keep the PPAs.
The keyd check costs an `apt-get update` on machines without keyd, skipped once keyd is installed.
Accepted limitations: any other apt distro, including other Ubuntu derivatives, silently gets its distro's fish until its `ID` is added; Debian testing, which has no `VERSION_ID`, is not handled.
Neither path was run on Debian or Ubuntu when this was decided.
