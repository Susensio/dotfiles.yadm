# ADR-0061: Manage tmux plugins with tpack through mise's github: backend, instead of tpm whose text parser cannot see declarations in conf.d or owning custom install scripts

Status: Accepted
Date: 2026-09-27
Supersedes: [ADR-0016](0016-adopt-tpm-reclaim-bindings.md)

## Context

The tmux config self-locates and includes everything through one line,
`source -F "#{TMUX_CONFIG_DIR}/conf.d/*.conf"` ([ADR-0010](0010-self-locating-tmux-conf.md)).
TPM discovers plugins by parsing tmux.conf's text plus whatever literal
`source-file` lines it can follow there; it can neither expand formats nor glob,
so `set -g @plugin` lines in conf.d were invisible to it. On 2026-09-27 a plugin
declaraton in conf.d silently installed nothing, and tpm's own directory was the
only plugin it ever saw.

The alternatives: declare plugins in tmux.conf itself (splitting the plugin
manifest out of the modular conf.d, and only working because tpm happens to read
that one file), or own a small parser/installer instead of tpm.

tpack (tmuxpack/tpack) parses the config the way tmux runs it: it resolves
formats, follows the source graph recursively and globs source paths, so it sees
declarations behind the wildcard include. It stores plugins under
hash-suffixed directories (`tmux-uzi-c2fffcfdc0b7`), so nothing may hardcode a
plugin's path; the old `tmux-uzi` and `tpm` directories do not survive an
upgrade to it. It binds prefix `I` / `U` / `M-u` popup TUIs and a TUI key at
init, and because `run` is asynchronous, unbinds written after the init line
race its binds.

## Decision

Plugins are managed by tpack, declared in `conf.d/90_plugins.conf` like any
other config, and initialized by `conf.d/99_tpack.conf`'s run line, which chains
the ADR-0016 unbinds after init so the reclaim wins the race. tpack's TUI key
moves to `S-Left`, a chord no one reaches through the prefix: its resolver
treats an empty `@tpack-tui` as unset and falls back to `T`, the tab table.
The tpack binary installs through mise's `github:` backend in `tools.toml`, so
both machines get the current release binary; mise's `go:` backend was rejected
because Go's module rules pin this repo to v1 tags, and v1 lacks the source
graph entirely.

## Consequences

Plugin declarations stay in the modular conf.d, and a new plugin is one
`set -g @plugin` line plus `prefix` + `C`, `I`. tpack's keybinding options carry
only its four keys, so a future tpack binding more keys silently would shadow
ours; the chained unbinds cover `I` / `U` / `M-u` only. tpack renames
existing plugin directories on install, which breaks any hardcoded plugin path
(there are none). The reclaim race is now load-bearing: if tpack ever binds
other prefix keys, the same chain must grow the unbinds.

## Corrections

- 2026-09-27 (same day): the run line no longer calls a bare `tpack`; it goes
  through `mise exec --` (and the config-table aliases with it). mise is a
  `/usr/bin` binary independent of the session PATH, auto-installs the declared
  tool when missing, and `tpack install` clones plugins that are not present, so
  a fresh machine's first server start bootstraps the manager and the plugins
  even when the session PATH is broken. This replaced the earlier guard on
  `command -v tpack` with one on `command -v mise`, which cannot paper over a
  broken session PATH because it never resolves through it.
- 2026-09-27 (same day): tpack's TUI no longer hides on a throwaway prefix
  chord; init's chain unbinds that key too, and the TUI sits in the config
  table on `T`, beside the reclaimed install/update/clean keys. The resolver
  cannot skip the bind (an empty key falls back to `T`), so the throwaway is
  load-bearing.
- 2026-09-27 (same day): the run line moved into `scripts/tpack-bootstrap`,
  which skips servers whose `#{config_files}` is not tmux.conf: reload-config's
  dry run starts one with `-f /dev/null`, and tpack cannot resolve its config
  root there, which surfaced as a `returned 1` status message on every reload.
- 2026-09-27 (same day, correction to both bullets above): the unbind chain was
  unnecessary — `run` blocks the config parse (timed: a 1s sleep makes
  source-file take 1s), so plain unbind lines after the run line land after
  tpack's binds, exactly like ADR-0016's original layout. The "run is async"
  claim came from a test where the observer had re-run `tpack init` by hand
  between spawn and observation. The script stays for the other two reasons:
  the dry-server skip and the broken-PATH bootstrap through mise.
- 2026-09-27 (same day, final): the script dissolved into its one caller —
  tmux's `if` expands formats in the condition, so the config-less skip became
  `if "command -v mise && printf '%s' '#{config_files}' | grep -q tmux.conf"`,
  which follows [ADR-0047](0047-helix-canonical-editor-name.md)'s rule against
  single-caller scripts. The TUI spent no prefix letter: a trial of `a` was
  declined, so tpack's obligatory TUI bind is a throwaway `S-Left` chord that a
  plain unbind line removes, and the TUI sits in the config table on `T`.
