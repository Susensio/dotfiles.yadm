# ADR-0045: Track mise tools in conf.d files and leave the global config.toml machine-local, instead of tracking it or redirecting it

Status: Accepted
Date: 2026-09-24

## Context

[ADR-0006](0006-manage-cli-tools-with-mise.md) declared every tool, setting and hook in mise's global `config.toml`, tracked by yadm.
A second machine was planned on Omarchy, whose installers write to that same file: each of its agent wrappers in `~/.local/bin` runs `mise use -g` on every call, provisioning pins `node` with `mise use -g node@<version>`, and it runs `mise settings set`.
On a tracked `config.toml` every one of those writes would have shown up as a yadm diff, and the `node` pin would have replaced `node = "latest"`.

Two alternatives were weighed.
Keeping `config.toml` tracked meant reverting other installers' writes by hand, indefinitely.
Pointing `MISE_GLOBAL_CONFIG_FILE` at a tracked file only moved the problem, since `mise use -g` writes to whichever file that variable names.

Tested on mise 2026.8.10: `[tools]`, `[tool_alias]`, `[settings]` and `[hooks]` all load from `conf.d/*.toml`; `mise use -g` always writes to `config.toml`; and a tool defined in both a `conf.d` file and `config.toml` resolves to the `conf.d` entry, with a warning.

## Decision

The tracked configuration lives in `conf.d`, split by what changes it: `tools.toml` (`[tools]` and `[tool_alias]`, written by `tool install`, `tool remove` and `tool alias`), `settings.toml` (`[settings]` and `[hooks]`, edited by hand) and the existing `lsp.toml`.
The global `config.toml` is untracked and listed in yadm's `exclude`, so it holds only machine-local tools: whatever other installers add, and anything installed with a plain `mise use -g`.
Tools were promoted into `tools.toml` one by one; the rest stayed local on the machine that had them.

## Consequences

Omarchy's writes, and any other installer's, stay on the machine that made them, and a tracked tool keeps its options even when an installer declares the same tool in `config.toml`, because `conf.d` wins.
`mise use -g` becomes the way to try a tool on one machine; `tool install` is the way to share it.
Costs: `tool` has to name the target file on every write, and `tool alias` does it through `MISE_GLOBAL_CONFIG_FILE` since `mise tool-alias set` has no `--path`; a tool declared in both places prints a mise warning; and nothing reports a local tool that was meant to be promoted.
