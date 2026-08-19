# ADR-0006: Manage CLI tools with mise

Status: Accepted
Date: 2026-01-25

## Context

CLI tools were fetched with eget (`eget/eget.toml`, ~25 entries) plus one bootstrap script per tool.
eget grabbed release binaries but had no concept of versions, man pages, or shell completions — each new tool meant hand-writing another script to place its binary and wire up whatever else it shipped.

## Decision

Manage CLI tools with mise, declared in `mise/config.toml`.

Tools come from the mise registry, `github:` releases, and `pipx:`.
Per-tool options fill the gaps eget left: `extra_assets` fetches completions and man pages not covered by a backend (delta, eza, fzf, helix's `languages.toml`, tmux), `gen_completions` runs a tool's own completion generator (herdr), `rename_exe` and `filter_bins` handle awkward upstream binary names.
A `postinstall` hook runs the `system-install` task — see [ADR-0007](0007-link-mise-tools-into-xdg.md).

## Consequences

One file replaces ~25 bootstrap scripts and gives version pinning, uninstalls, and asset management for free.
Costs: relies on `experimental = true` mise settings, which can change or break across releases; `github:`-backed tools hit GitHub API rate limits and need `use_git_credentials` to stay usable; `mise/config.toml` is now a single point of failure for the whole toolchain.

