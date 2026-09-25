# ADR-0046: Source CLI tools per distro through packages.toml variants, decided on the machine with a choice, instead of a generated disable list or a pacman key on every tool

Status: Superseded by [ADR-0048](0048-direct-arch-tool-install.md)
Date: 2026-09-24

## Context

After [ADR-0045](0045-mise-conf-d-over-global-config.md), every tool in `conf.d/tools.toml` was installed through mise on every machine.
The planned main machine ran Omarchy on Arch, whose repositories packaged most of those CLIs with man pages and completions, updated by `omarchy update`.
Linux Mint, now the secondary machine, had most of them missing or years old in apt, so mise stayed the answer there, and a later Ubuntu server would be in the same position.

Several shapes were weighed.
A tracked `pacman.toml` plus a static `disable_tools` list failed on two tested mise behaviours: `disable_tools` is replaced, not merged, by a higher-precedence file, and a disabled tool stays ignored even after `mise use -g`, so a local override was impossible.
Generating `disable_tools` per machine from `pacman.toml` avoided that, but needed a generator script and a regeneration step after every change.
A `pacman = "<pkg>"` key on every tool in `tools.toml` put the source in one place but forced that key onto each entry.
Custom fields inside `[bootstrap.packages]` were rejected outright by mise's config parser.
A command-line flag naming the source or a category (`--cli`, `--mise`, `--edge`, `--toolchain`) could not stay true on every machine, since on Mint both paths ended in mise.

## Decision

The tools whose source depends on the distro live in one yadm-alternate file, `conf.d/packages.toml`, with exactly one variant linked per machine.
`packages.toml##distro.arch` declares them as `[bootstrap.packages]` `"pacman:<pkg>"` entries, installed by `mise bootstrap`, with hooks for Arch specifics (removing Omarchy's `tldr`, which conflicts with tealdeer; linking `hx` to Arch's `helix`).
`packages.toml##default` declares the same tools as mise `[tools]`, options included.
`tools.toml` keeps what comes from mise on every machine: agents, runtimes, herdr, and anything no distro packages.

The choice is made on the machine that has one.
On Arch, `tool install` puts a new plain tool name that `pacman -Si` finds into both variants, writing each by its full path; everything else, and anything installed on another machine, goes to `tools.toml`.
The same command promotes a tool installed with plain `mise use -g`, dropping it from the local `config.toml`.
Rare cases stay manual rather than growing `tool`: forcing mise for a tool pacman packages, an Arch package named differently from its tool, and moving a `tools.toml` entry with options into the variants.
The yadm bootstrap runs `mise bootstrap --only packages` and then `mise install`, so each machine installs from whichever variant it has.

## Consequences

Each machine sees a plain set of files, needs no generated state, and a local `mise use -g` overrides a distro tool simply by coming first on `PATH`.
Adding a distro for a tool is a matter of adding its variant, e.g. an apt one for a server whose packages are recent enough.
Costs: each distro-sourced tool is written twice, once per variant under that variant's name, and only `tool` keeps them paired; differently named packages (`git-delta`, `pandoc-cli`) are paired by hand, and `tool remove` cannot find them; and the Arch variant, its hooks and `tool install`'s Arch branch were written on Mint, untested until the Omarchy machine exists.
