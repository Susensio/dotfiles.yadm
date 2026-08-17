# ADR-0016: Adopt TPM but reclaim its hardcoded bindings

Status: Accepted
Date: 2026-06-02

## Context

A plugin manager is needed for future tmux plugins. TPM is the standard
choice, but it hardcodes prefix-table bindings (`I`, `U`, `M-u`) with no
config option to opt out — `@tpm-install` and friends name the key to bind,
and an empty value just falls back to the default. Naming a key tmux rejects
(`None`) works too, but reports "unknown key" into `show-messages` on every
load. Its default plugin path also lives outside `$XDG_DATA_HOME`.

## Decision

Adopt TPM in `conf.d/99_tpm.conf`, relocate `TMUX_PLUGIN_MANAGER_PATH` to
`$XDG_DATA_HOME/tmux/plugins`, and self-install via `git clone` if absent.
Unbind its `I`/`U`/`M-u` prefix bindings immediately after its `run` line,
then re-expose install/update/clean through command aliases bound in the
`config` table instead. Unbinding after `run` is the only clean way to
reclaim those keys.

## Consequences

Plugin install/update/clean stay reachable but through this config's own
table convention instead of TPM's bare prefix bindings. Costs: a plugin
manager is carried for zero plugins right now — `90_plugins.conf` is empty,
TPM manages only itself. The unbind block has an ordering dependency: it
must stay after the `run` line, both file-internally and via
[ADR-0011](0011-give-each-tmux-topic-its-own-conf-d-file-and-keep.md)'s
numeric `conf.d` ordering that keeps `99_tpm.conf` loading last — move
either and the unbind silently stops working, since TPM would rebind those
keys after the unbind ran.
