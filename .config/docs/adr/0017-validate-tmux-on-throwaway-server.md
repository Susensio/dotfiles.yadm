# ADR-0017: Validate tmux config on a throwaway server before reloading

Status: Accepted
Date: 2026-08-06

## Context

`conf.d/00_reset.conf` wipes every binding and command-alias before later files rebuild them, and bindings are written in terms of aliases from `15_aliases.conf`.
A syntax error partway through a reload leaves gaps in a live server that already had its bindings cleared — potentially dropping the reload binding itself, `r`, with no way to retry short of restarting the server.

## Decision

`scripts/reload-config` sources `tmux.conf` on a throwaway server first — started with `-f /dev/null` on its own `-L` socket, so it inherits nothing from the live config — and only sources it onto the live server if that dry run reports no errors.
It also reloads the paired main/scratchpad server when one exists (see `scripts/scratchpad`, [ADR-0015](0015-custom-sessionizer-and-scratchpad.md)).

## Consequences

A rejected reload surfaces as a message instead of a half-applied config on the live server, and both paired servers stay in sync on every reload.
Cost: roughly 0.3s added to every reload.
The dry run only proves the config parses and applies cleanly on a fresh server — it says nothing about semantic correctness, or about how it composes with the live server's existing state (options already set, hooks already fired).
The live server is still re-sourced afterward and can report its own errors independently of the dry run passing.
