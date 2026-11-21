# ADR-0003: Enter interactive shells through bash and exec into fish

Status: Accepted
Date: 2026-06-02

## Context

Fish is the primary interactive shell but isn't POSIX, and login managers, `ssh`, and scripts that `source` a profile all expect a POSIX entry point.
Separately, `gnome-terminal-server` inherits its environment from whatever session first activated it and stays stuck with it; a running terminal server doesn't see later environment changes, so every new tab it spawns starts stale unless something re-pulls the environment at shell start (`environment-architecture.md` §4).

## Decision

Sessions enter through `/bin/bash`, which `exec`s into `fish` when interactive.
Login-shell status is the trigger: `fish/conf.d/01_environment.fish` runs `_env_pull` only `if status is-login`, bypassing the stale terminal-server environment by fetching fresh values from `systemd --user` on every new login shell.
`~/.config/profile` covers the no-`DISPLAY` case (TTY/SSH), pulling before handing off to `bashrc` (§5).

## Consequences

Terminals stay correct after an `env_reload` without restarting the terminal server or relogging in, and bash still works as the POSIX entry point tools expect.
Trade-off: two shell startups per terminal instead of one; `exec` discards any bash-level state (aliases, exported vars set only in `bashrc`) since it doesn't fork; and the relay is a two-file contract (`bashrc` and `01_environment.fish`) that's easy to break by editing only one side.

## Amendment (2026-11-20)

The login trigger proved to be a POSIX-era proxy that every terminal had to opt into with its own spelling: foot pins `bash --login`, tmux gets login fish only through its empty `default-command` convention, and herdr panes and the scratchpad wrapper — non-login — shipped a stale `PASSWORD_STORE_DIR` until `env_reload` ran.
`fish` never reads profile, so login status never meant "env loading" for it, only a boolean `conf.d` could check.

The fish-side trigger is now `status is-interactive; or status is-login`: every pane, popup and nested interactive fish pulls at start, whatever flag the launcher passed, and a login fish still pulls when non-interactive, preserving the `fish -lc` script entry that `ssh nuc`'s `clipboard` path depends on ([ADR-0113](0113-osc52-copy-over-ssh.md)).
`fish -c` stays pull-free and inherits, and `~/.config/profile`'s bash pull is unchanged: bash keeps the login doorbell because that is what makes profile run; the two doors fetch the same store.
A failed fetch now keeps the current environment instead of pruning (`_env_pull` guard), since an interactive shell can outlive its user manager.

Accepted consequence: a nested interactive fish re-pulls and re-overrides with manager values, so a hand-exported var shadowed by the manager resets on nesting; the freshness of every interactive shell is worth more than preserving ad-hoc overrides across nesting.
`PATH` is the sharp edge of that choice: the manager exports it, so a nested interactive fish — or `env_reload` in the current one — replaces the shell's `PATH` wholesale with the manager's, dropping a venv's `bin/`, a direnv prepend, or any ad-hoc `PATH=...` export inherited into the nested shell. Un-shadowed extras such as `VIRTUAL_ENV` survive, so an activated venv keeps its markers but loses the interpreter from `PATH` — a stale activation rather than a clean exit. `fish -c` stays pull-free, so `PATH=whatever ./script` and one-shot `fish -c` commands keep their export; only nesting into an interactive shell can drop it. Accepted: per-shell `PATH` edits are ephemeral by design — durable ones belong in `environment.d`, and `environment-architecture.md` §4a records the `fish -C 'set -gx PATH ...'` workaround for the ephemeral cases that must survive nesting.

