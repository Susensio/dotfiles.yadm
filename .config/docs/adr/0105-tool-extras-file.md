# ADR-0105: Keep settings mise would reject in tool-extras.toml, keyed by tool, instead of as options on the tool's declaration

Status: Accepted
Date: 2026-11-05

## Context

[ADR-0006](0006-manage-cli-tools-with-mise.md) extended tool declarations with options of our own: `extra_assets` fetched completions and man pages, `gen_completions` and `gen_shell_init` ran a tool's own generators, and [ADR-0048](0048-direct-arch-tool-install.md) added a `pacman` field naming the Arch package a differently named tool came from. `system-install`, `discover-assets.py` and `~/bin/tool` read them from mise's own tool metadata.

mise 2026.11 changed that. [jdx/mise#14629](https://github.com/jdx/mise/pull/14629) made `mise install` fail on any tool option the backend does not read. The `github` backend rejected the keys first, so a Debian bootstrap died on `pandoc`'s `pacman` field; aqua and core backends were still unchecked, so the rest passed, but nothing bound the two backends' behaviour to the config.

A first test of the option check suggested moving only `pandoc`'s field. That reading was wrong in the other direction too: an earlier verdict that the option check rejected every key on every backend was noise from a polluted test config. What held after re-running against the isolated config was only the structural problem — these fields are not options at all, they are per-tool data of ours, and whatever past readers assumed, `tool remove` dropped them with the declaration (which had already been observed as odd behaviour).

Keeping them as declarations was rejected: it depends on which backends mise checks, and the check list only grows.
A third file per tool (`mise/metadata/<tool>.toml`) added a directory walk to every reader for no gain over one file, which every reader already opens once.

## Decision

Custom per-tool settings live in `mise/tool-extras.toml`, keyed by tool name, with a comment saying what it is and that mise never reads it. Each tool's table holds `extra_assets`, `gen_completions`, `gen_shell_init` or `pacman` as they appeared on the declaration. Tool declarations themselves carry only options mise reads.

The file sits outside `mise/conf.d/`, which mise merges; a file there with unknown fields warns on every invocation.

Readers reach it over `mise config get --file`:
`system-install` reads `extra_assets`, `gen_completions` and `gen_shell_init` through a `tool_extra` helper; `discover-assets.py` writes new `extra_assets` there with tomlkit, no longer edits tool declarations, and no longer needs to find which config file declares a tool; `~/bin/tool`'s `pacman_package` reads `pacman` from there.

## Consequences

A `tool remove` keeps the tool's settings, so reinstalling it is a one-line change and the metadata is curated state, not a side effect of an install.
mise rejects nothing, on any backend, present or future.
The declaration no longer shows what `system-install` will do for a tool; both halves must be read together.
Costs: an empty `tool-extras.toml` exists on any machine whose tools all need nothing, and the file may name a tool that is not installed anywhere.
The hook strings in `tools.toml` keep their post-AADR-0060 `--skip-tools` form without change, and the correction to ADR-0048's `pacman` field line is recorded there.
