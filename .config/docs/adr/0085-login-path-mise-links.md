# ADR-0085: Reach Mise's global tools from a login shell through ADR-0007's links, instead of login-profile shims or mise env

Status: Accepted
Date: 2026-10-08

## Context

maniac began resolving tools through `$SHELL -lc 'printenv PATH'`, run at `$HOME` with the caller's environment minus activation state (maniac ADR-0062).
Its premise was the conventional setup: the login profile builds the environment, and Mise's own docs pair `mise activate --shims` in the profile with `mise activate` in the rc file.
Here, `profile` imported the user manager's environment ([ADR-0043](0043-drop-display-guard-filter-env-import.md)), whose `PATH` came from `environment.d` and put `~/.local/bin` ahead of the shims that Omarchy's `env-bootstrap` appended.

Three ways to put Mise's globals on the login `PATH` were weighed.
`mise activate --shims` in the profile was the shims maniac could not claim, at the cost [ADR-0007](0007-link-mise-tools-into-xdg.md) measured.
`eval "$(mise env -s bash)"` gave the install directories when run from `$HOME`, but built the whole toolset on every login shell, the cost ADR-0007 measured at hundreds of milliseconds for about fifty tools, and from inside a project it also exported that project's tools and `[env]`.
ADR-0007's links in `~/.local/bin` already resolved into the installs directory, and maniac resolves symlinks before claiming.

## Decision

The login profile runs no Mise.
Global tools reach a login shell's `PATH` through ADR-0007's links, in the order `environment.d` sets.

## Consequences

A login shell costs nothing extra, and its answer is the same from any directory.
A Mise tool reaches the login `PATH` only once `system-install` has linked it; one installed without the postinstall hook resolves to its shim, or to a system copy, until `mise run system-install` runs.
The login `PATH` depends on reaching the user manager: a shell started without `XDG_RUNTIME_DIR`, such as under `env -i`, from cron or through `su`, gets no `environment.d` at all.
A fallback through systemd's `environment.d` generator was written and dropped, since nothing that needs the login `PATH` starts that way.
