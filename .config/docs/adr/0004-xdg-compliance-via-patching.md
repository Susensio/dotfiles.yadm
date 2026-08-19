# ADR-0004: Enforce XDG compliance by patching system files

Status: Accepted
Date: 2026-06-02

## Context

Keeping `$HOME` XDG-compliant requires more than user-level dotfiles: LightDM and the system `bash.bashrc`/`profile.d` read their own configuration before any user config runs, and hardcode `$HOME`-relative paths (`.Xauthority`, `.bash_history`, `.sudo_as_admin_successful`, `/etc/bash.bashrc`).
No environment variable set from user space can redirect them.

## Decision

Patch the system files directly.
`yadm/bootstrap.d/xdg_compliance/` installs assets into `/etc/bash.bashrc` (via patch), `/etc/bashrc.d/xdg.sh`, `/etc/profile.d/{bash_xdg.sh,profile_xdg.sh}`, `/etc/X11/Xsession.d/{00xdg-compliance,96fix-env-precedence}`, `/etc/lightdm/lightdm.conf` (XAuthority redirect), and `/etc/sudoers.d/disable_admin_file`, then moves the corresponding user dotfiles into `~/.config/`.
See `ENVIRONMENT_ARCHITECTURE.md` §6.

One exception is accepted rather than fought: `~/.xsession-errors` is unfixable in userspace — its path is compiled into the `lightdm` daemon binary and written before any session-wrapper script runs (upstream canonical/lightdm#95, unaddressed).
Monitored manually instead.

## Consequences

`$HOME` stays clean without waiting on upstream XDG support in bash or LightDM.
Costs: every bootstrap run needs sudo; the patches live outside the yadm-tracked repo, so they aren't version-controlled on the target machine; package upgrades to `bash` or `lightdm` can silently revert them; and a fresh OS install is XDG-noncompliant until bootstrap re-applies the patches.

