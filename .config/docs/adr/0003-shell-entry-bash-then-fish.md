# ADR-0003: Enter interactive shells through bash and exec into fish

Status: Accepted
Date: 2026-06-02

## Context

Fish is the primary interactive shell but isn't POSIX, and login managers, `ssh`, and scripts that `source` a profile all expect a POSIX entry point.
Separately, `gnome-terminal-server` inherits its environment from whatever session first activated it and stays stuck with it; a running terminal server doesn't see later environment changes, so every new tab it spawns starts stale unless something re-pulls the environment at shell start (`ENVIRONMENT_ARCHITECTURE.md` §4).

## Decision

Sessions enter through `/bin/bash`, which `exec`s into `fish` when interactive.
Login-shell status is the trigger: `fish/conf.d/01_environment.fish` runs `_env_pull` only `if status is-login`, bypassing the stale terminal-server environment by fetching fresh values from `systemd --user` on every new login shell.
`~/.config/profile` covers the no-`DISPLAY` case (TTY/SSH), pulling before handing off to `bashrc` (§5).

## Consequences

Terminals stay correct after an `env_reload` without restarting the terminal server or relogging in, and bash still works as the POSIX entry point tools expect.
Trade-off: two shell startups per terminal instead of one; `exec` discards any bash-level state (aliases, exported vars set only in `bashrc`) since it doesn't fork; and the relay is a two-file contract (`bashrc` and `01_environment.fish`) that's easy to break by editing only one side.

