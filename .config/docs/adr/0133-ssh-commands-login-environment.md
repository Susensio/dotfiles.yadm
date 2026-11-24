# ADR-0133: Give SSH commands the login environment from the head of /etc/bash.bashrc

Status: Accepted
Date: 2026-11-24

## Context

`nuc` is a Debian host reached over Tailscale SSH.
`ssh nuc cmd` runs `/bin/bash -c cmd`: non-login, non-interactive, no PAM, so the environment is bare (`PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games`, no `XDG_*`).
Tailscale SSH commands do register logind sessions, so the systemd user manager is running whenever one executes.
The XDG bootstrap removed `~/.bashrc`.
Debian's bash still sources `/etc/bash.bashrc` for SSH commands (verified with xtrace and a temporary `HOME`), but that file returns at its first line, `[ -z "${PS1-}" ] && return`, since bash unsets `PS1` when non-interactive.
The bootstrap's `/etc/bashrc.d/*.sh` loop sits at the end of that file, below the guard, so it never runs for SSH commands.

Everything started by `ssh host cmd` therefore inherits the bare environment: herdr's saved-machine bridge and the remote `herdr server` it launches, a `ssh -t nuc tmux` server, and their popups and `run-shell` commands.
Interactive fish panes are unaffected because fish pulls the manager environment at startup ([ADR-0003](0003-shell-entry-bash-then-fish.md)).
This broke the herdr scratchpad popup on nuc: bare `herdr` was not on `PATH`, and `2>/dev/null` hid the error.
`~/.config/profile` already does the login-shell pull ([ADR-0043](0043-drop-display-guard-filter-env-import.md)) and is the one implementation to reuse.

## Decision

The bootstrap inserts one line at the top of `/etc/bash.bashrc`, above the guard (`yadm/bootstrap.d/10_xdg_compliance/assets/etc/bash.bashrc.head`):
it sources `profile` when `PS1` is unset and `SSH_CLIENT` is set.
Interactive shells have `PS1` set and skip it; non-SSH non-interactive shells skip it.
Output and errors are discarded, so a broken or missing `profile` leaves today's bare environment.
The step is idempotent on the `(ADR-0133)` marker in the line's comment.
The existing `bashrc.d` loop stays at the end of the file.

Alternatives rejected:
- A `~/.bashrc` stub: a file in `$HOME`, against the XDG clean-home rule.
- Moving the `bashrc.d` loop above the guard: stock `/etc/bash.bashrc` settings then override the user's `PS1` and the like.
- `~/.ssh/environment`: OpenSSH-only, needs `PermitUserEnvironment`, Tailscale SSH ignores it, and it is a static copy of `environment.d`.
- PAM or `/etc/environment`: Tailscale SSH skips PAM, and it duplicates `environment.d`.
- The herdr server as a systemd unit: undocumented by herdr, and its upgrade flow relaunches over SSH anyway.
- Herdr-only `HERDR_BIN_PATH`: leaves tmux and any other SSH-launched server bare.

## Consequences

Each SSH command pays about 14 ms on nuc for the `systemctl` pull.
Bash only: a host whose login shell became fish would not pull for `fish -c`, per ADR-0003.
It edits a Debian conffile, so a package upgrade may replace it; the bootstrap re-applies the line.
Interactive logins are unaffected, so a bad `profile` cannot lock anyone out.
A server launched this way keeps the pulled environment for life, and its non-shell children (popups, `run-shell`) inherit it rather than pulling.
Arch's bash does not source `/etc/bash.bashrc` for SSH commands (same xtrace check, nothing sourced), so the line is inert there.
