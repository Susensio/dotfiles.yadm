# ADR-0053: Use Projects for Omarchy agents and remove untouched Work instead of linking it

Status: Accepted
Date: 2026-09-26

## Context

Omarchy 4.0.4 created `~/Work/tries` and a trusted `.mise.toml` under `~/Work`, and its agent launcher switched from `$HOME` to `~/Work`.
The dotfiles already treated `~/Projects` as the repository root across distros, while Fish disabled automatic mise activation.
Moving Omarchy's `.mise.toml` to `~/Projects` would have introduced a PATH rule for every project without a current use for it.
Linking `Work` to `Projects` would have had the same effect and kept two names for one location.

## Decision

Keep repositories and home-launched Omarchy agents in `~/Projects`.
Override `omarchy-agent` through the existing first-on-PATH override directory, forwarding all arguments to the real launcher after changing from `$HOME` to `~/Projects`.
Match Omarchy's exact `~/Work` fallback line; if it changes, warn and let the upstream launcher choose the directory.
During Omarchy bootstrap, remove `~/Work` only when it is empty or contains exactly the installer's unchanged `.mise.toml` and empty `tries` directory.
Do not move that `.mise.toml` to `~/Projects`.

## Consequences

The wrapper leaves launches from an existing project in that project.
User files under `~/Work` prevent cleanup, and rerunning Omarchy's user provisioning can recreate the installer state until the dotfiles bootstrap runs again.
Omarchy's default Bash `try` setup still names `~/Work/tries`; adopting `try` in Fish will need an explicit `~/Projects/tries` path.
