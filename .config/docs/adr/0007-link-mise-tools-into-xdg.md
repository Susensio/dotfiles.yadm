# ADR-0007: Link mise tools into XDG directories instead of PATH shims

Status: Accepted
Date: 2026-06-02

## Context

mise's default integration puts its shims on `PATH` and needs `mise activate` in
every shell. That means a shell hook on every startup and a layer of shim
indirection between the shell and the real binary, for every invocation.

## Decision

Symlink mise-managed tools into standard XDG locations instead of using shims.
The `system-install` task ([ADR-0006](0006-manage-cli-tools-with-mise.md)'s
`postinstall` hook) links binaries into `~/.local/bin`, man pages into
`$XDG_DATA_HOME/man`, fish completions into
`$XDG_DATA_HOME/fish/vendor_completions.d`, and node modules into
`$XDG_LIB_HOME/node_modules`, using `ln --relative`. Man pages and completions
land where the normal lookup paths already find them — no shell hook required.

## Consequences

Shells start faster and stay ignorant of mise. Costs: the symlink farm is a
second source of truth that must be re-synced after every install or uninstall
(`prune_broken_links` walks `TARGET_DIRS` for dangling links via
`find -xtype l -lname "*/mise/*"`); the guard that stops this running from a
local project (`check_execution_context`, walking the PPID chain for a
`--global`/`system-install` invocation) is a fragile heuristic, not a real
sandbox; and because resolution no longer goes through mise for these globals,
per-directory version switching does not apply to them.

