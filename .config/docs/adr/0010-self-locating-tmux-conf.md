# ADR-0010: Make tmux.conf self-locating and glob-source conf.d

Status: Accepted
Date: 2026-08-07

## Context

Dotfiles are yadm-managed and cloned to different machines/paths.
`tmux.conf` and `scripts/` need to find each other and `conf.d/` regardless of where the clone lives, without a hardcoded absolute path baked in anywhere.

## Decision

`tmux.conf` derives its own directory at runtime and glob-sources `conf.d/` from there.
`set-environment -ghF` sets `TMUX_CONFIG_DIR`, `TMUX_SCRIPTS_DIR`, and `BIN_HOME` from `#{d:current_file}`, then `source -F "#{TMUX_CONFIG_DIR}/conf.d/*.conf"` pulls in every topic file ([ADR-0011](0011-per-topic-tmux-conf-d-files.md)).

## Consequences

No absolute paths anywhere in the config; it works from any clone location, and scripts resolve off the same root via `$TMUX_SCRIPTS_DIR`.
Costs: relies on recent tmux format features (`#{d:}`, `-F` on `set-environment`/`source`).
The three variables are set with `-g`, so they land in the global server environment and are visible in every pane, not just tmux's own commands.
`-F` was picked over the cheaper `%hidden` deliberately: `%hidden` values are substituted into `$VAR` only at parse time and are invisible to `#{}` lookups made later, which `source -F` needs.
