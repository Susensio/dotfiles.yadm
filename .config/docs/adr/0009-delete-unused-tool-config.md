# ADR-0009: Delete configuration for tools no longer used

Status: Accepted
Date: 2026-06-02

## Context

Config had accumulated for tools no longer in active use: `lf`, `cidm`, `anacron`, `eget`, `cookiecutter`, `solaar`, `python/startup.py`, `fd/ignore`, plus their bootstrap scripts.
Some were superseded by this same refactor — `eget` by [ADR-0006](0006-manage-cli-tools-with-mise.md), `lf` by the nvim-integrated file manager usage removed in [ADR-0008](0008-replace-neovim-with-helix.md) — others fell out of use.
Carrying dead config costs nothing to run but adds noise to every future search of the repo.

## Decision

Delete configuration for tools no longer used, as a standing policy rather than a one-off cleanup: when a tool is dropped, its config goes with it in the same change.

## Consequences

Fewer stale files to wade through when searching or bootstrapping a new machine.
Cost: deleting a config without auditing what still references it leaves dangling pointers.
Concrete case from this pass: `environment.d/10_xdg.conf` still sets `PYTHONSTARTUP=$XDG_CONFIG_HOME/python/startup.py`, but `python/startup.py` was deleted along with the rest — interactive `python3` now prints `Could not open PYTHONSTARTUP` and a `FileNotFoundError` on every start.
Left as-is here; the fix is a separate decision.

