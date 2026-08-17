# ADR-0008: Replace Neovim with Helix

Status: Accepted
Date: 2026-06-02

## Context

`nvim/` held a full lazy.nvim setup — `init.lua`, ~30 plugin specs, LSP/lint
config, ftplugins, ftdetect, snippets, spell files — accumulated over years and
last touched in `eb8baa7`. Maintaining a plugin-manager-driven config had grown
into its own ongoing cost.

## Decision

Replace Neovim with Helix. `nvim/` is deleted outright (80+ files); `helix/`
holds `config.toml`, `languages.toml`, `runtime/`, `themes/`. Helix is installed
via mise with `extra_assets = ["raw://languages.toml"]`
([ADR-0006](0006-manage-cli-tools-with-mise.md)). `EDITOR`/`SUDO_EDITOR` in
`environment.d/tools.conf` now point at `hx`.

## Consequences

Config surface shrinks from a lazy.nvim plugin graph to a couple of TOML files —
less to maintain, less that can break on plugin updates. Cascades: `lazygit/config.yml`
is now empty, since its `editPreset: nvim` and delta pager settings became
redundant once git's own config is canonical; tmux copy mode now defaults to
helix motion semantics, addressed in
[ADR-0014](0014-keep-vim-and-helix-copy-mode.md). Costs: gives up
the neovim plugin ecosystem and years of tuning outright; helix's smaller config
surface is also a less extensible one; muscle memory has to be retrained.

