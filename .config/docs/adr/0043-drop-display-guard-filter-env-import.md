# ADR-0043: Drop profile's DISPLAY guard and filter systemd's environment on every sh import

Status: Accepted
Date: 2026-09-10

## Context

[ADR-0003](0003-shell-entry-bash-then-fish.md) has `~/.config/profile` pull from `systemctl --user show-environment` only when `$DISPLAY` and `$WAYLAND_DISPLAY` are both unset — the TTY/SSH case.
In a graphical session an **interactive** login shell never reaches that gate: `bash/bashrc` `exec`s into `fish` before `profile`'s pull line runs, and `01_environment.fish` calls `_env_pull` itself.
But a **non-interactive** login shell (`bash -lc '...'`) is not interactive, so `bashrc` returns early instead of exec'ing, and control falls through to the gated pull in `profile` — which stays closed in a graphical session.
That shell is left with whatever `$PATH` (and everything else) it happened to inherit, with no route to `environment.d`'s prepends (`environment.d/11_path.conf`) at all.
This surfaced while implementing ADR-0020 in the `maniac` repository, which spawns `$SHELL -lc 'printenv PATH'` specifically to learn the machine's `$PATH` rather than trusting an inherited one — the exact case the guard defeats.
Anything that shells out this way hits the same gap: build scripts, an editor resolving a linter, `ssh host 'command'`, a systemd unit with `ExecStart=/bin/bash -lc`.

The guard's stated purpose was to avoid a double `systemctl` call, since `bash` and `fish` both pull on the interactive path.
That is already guaranteed by ordering, not by the guard: `profile` sources `bashrc` before its own pull line, and an interactive `bashrc` `exec`s into `fish`, replacing the process before that later line is ever reached.
The guard only ever gates the non-interactive case, where `fish` never runs and there is no second call to prevent — so it can be dropped without reintroducing a double pull.

Dropping the guard means `profile` now imports `systemctl --user show-environment` unconditionally, and that output is not safe to import verbatim.
Measured live on this machine, it includes `PWD=/home/susensio`, `SHLVL=0`, `USER`, `HOME`, `SHELL`, and `_=/usr/bin/dbus-update-activation-environment` alongside the real, generator-owned variables.
`fish/functions/environment/_env_fetch.fish` already strips exactly these six names (`readonly_vars: PWD USER HOME SHELL SHLVL _`) before `_env_pull` imports anything, precisely because importing `PWD` desynchronises it from the actual working directory and `SHLVL` is load-bearing in `bashrc`'s exec condition.
`profile`'s `eval "$(systemctl --user show-environment)"` and `X11/xsessionrc`'s `source <(systemctl --user show-environment)` have the same unfiltered shape and no such filter — the latter already runs unconditionally today (guarded only by `$DBUS_SESSION_BUS_ADDRESS`), so this is a latent bug independent of the guard being dropped, not one introduced by dropping it.
`xsessionrc` runs inside the `Xsession` script, which `exec`s onward into `cinnamon-session` — a corrupted `$PWD`/`$SHLVL` there propagates into every graphical app and every terminal opened for the rest of the session, not just the one script.
It hasn't been observed as a live symptom only because the current captured values happen to be harmless: `SHLVL=0` still lands `bashrc`'s `^[12]$` check in range once a shell increments it, and `PWD`/`HOME`/`USER`/`SHELL` happen to already equal the real values for this user.
None of that is structural.

## Decision

Drop the `$DISPLAY`/`$WAYLAND_DISPLAY` guard in `profile`: it pulls from `systemctl --user show-environment` whenever `systemctl` is available, regardless of session type.
Before importing, both `profile` and `X11/xsessionrc` now filter out the same six shell-managed names `_env_fetch.fish` already denies: `PWD`, `USER`, `HOME`, `SHELL`, `SHLVL`, `_`.
Each file gets its own inline `grep -Ev '^(PWD|USER|HOME|SHELL|SHLVL|_)='` rather than sourcing a shared script — see Consequences for the trade-off.
Fish's `_env_pull`/`_env_fetch` are unchanged: they already filter correctly and were never part of this gap.

Two alternatives were weighed and discarded:
- Leaving the guard in place and having `maniac` (or any similar tool) call `systemctl --user show-environment` directly instead of going through a login shell.
  Measured faster (13ms against the login shell's 57ms), but it hard-codes this machine's environment-sync architecture into a portable tool, fixing exactly one consumer instead of the general case.
- Filtering by allowlist instead of denylist — importing only the names `environment.d`'s generator owns, the same technique `_env_unpin` and `96fix-env-precedence` already use to scope the *unpin*.
  Discarded because it would also stop importing `DISPLAY`, `XAUTHORITY`, and other dynamically pinned names that aren't generator-owned, narrowing what gets imported beyond what's needed to fix the corruption; the denylist matches `_env_fetch`'s already-accepted behavior instead of introducing a second, differently-scoped filter.

A shared `sh/_env_pull.sh` sourced by both `profile` and `xsessionrc` was also drafted and discarded in favor of the inline duplication above, per the trade-off recorded below.

## Consequences

A non-interactive graphical login shell (`bash -lc '...'`) can now reconstruct its own `$PATH`, `$EDITOR`, and `XDG_*` instead of only inheriting the caller's, closing the gap `maniac` hit.
`X11/xsessionrc` no longer risks leaking `$PWD`/`$SHLVL`/etc. into the whole graphical session on a machine where `systemctl --user show-environment` happens to report different values than it does today.
`profile` now makes one unconditional `systemctl` call (~44ms) for every non-interactive login shell and every login shell past `SHLVL` 2; interactive shells at `SHLVL` 1-2 are unaffected, since `bashrc` still `exec`s into `fish` before reaching that line.
The six-name denylist now lives in three places — `_env_fetch.fish`, `profile`, `xsessionrc` — instead of one; letting one copy drift out of sync with the others silently reopens this exact class of bug in whichever file was missed, and nothing enforces the sync automatically.
This narrows [ADR-0003](0003-shell-entry-bash-then-fish.md)'s claim that `profile` "covers the no-`DISPLAY` case (TTY/SSH)": it now covers every case, and that ADR's bash-then-fish relay decision otherwise stands unchanged.
