# Packages and tools

Where each kind of software is declared and what installs it.
The reasoning lives in the ADRs; this file is the current map.
When the two disagree, the ADR is right and this file is a defect.

## Where does it go?

| It is... | Declare it in | Installed by |
| --- | --- | --- |
| A CLI tool from a release, npm, pipx, cargo or aqua | `mise/conf.d/tools.toml` (`lsp.toml` for language servers) | `mise bootstrap --only tools`, then the `system-install` hook links it into XDG paths |
| A tool a distro packages, and the same tool through mise elsewhere | `mise/conf.d/packages.toml`, both variants | Arch: pacman through `mise bootstrap`; other distros: mise from the default variant |
| An Omarchy-only package, kept or removed, or an AUR package | `mise/conf.d/omarchy.toml##distro.omarchy` | `mise bootstrap --only packages` (`pacman:`, `aur:`) |
| A command a script needs, with the same package name on every distro | `yadm/bootstrap.d/dependencies.txt` | `00_dependencies.sh` through `~/bin/pkg-install` |
| A daemon, a repository or anything needing root setup | its own step in `yadm/bootstrap.d/` | the step, gated on what the machine has (ADR-0044) |
| A setting mise would reject on a tool (extra assets, generators, a differently named pacman package) | `mise/tool-extras.toml`, keyed by tool | read by `system-install`, `discover-assets.py` and `~/bin/tool`, never by mise |
| A tool tried on one machine only | `mise use -g` | nothing: it lands in the untracked `config.toml` |

## Files

- `mise/conf.d/*.toml` is merged by mise.
  Tracked config lives here and the global `config.toml` stays untracked and machine-local, because other installers write to it (ADR-0045).
- `tools.toml` holds `[tools]` and `[tool_alias]`, written by `tool install`, `tool remove` and `tool alias`.
- `settings.toml` holds `[settings]`, `[hooks]` and the tool-update service, edited by hand.
- `packages.toml` is a yadm alternate with two variants, `##default` (mise tools) and `##distro_family.arch` (`[bootstrap.packages]` with `pacman:` entries).
  Keep them in sync; on Arch `tool install` writes both and runs `pacman -S` itself (ADR-0048).
- `omarchy.toml##distro.omarchy` is Omarchy's preinstalls, one `latest` or `absent` per package, plus `aur:` entries (ADR-0049, ADR-0102).
  `aur:` has no pins and no `absent`; `yay` or `paru` and `base-devel` are prerequisites that `00_dependencies.sh` checks for.
- `tool-extras.toml` sits outside `conf.d/` so mise never reads it (ADR-0105).
- No tool declares `auto_update`, so harness versions move only through `mise up` or `pi update` (ADR-0112).
  `pi`'s tool postinstall runs `mise/tasks/pi-postinstall`, which reapplies patches, rebuilds the bundles, checks every declared extension's peers against the pi that just landed, and syncs herdr.
- `dependencies.txt` lists `command [package]` per line.
  A name that differs between distros cannot go there and needs its own step.

## Bootstrap order

`yadm/bootstrap` runs every executable in `bootstrap.d/` in sorted order, each changing nothing on a rerun (ADR-0005, ADR-0111).

1. `00_dependencies.sh` installs `dependencies.txt` and checks the AUR prerequisites.
2. `20_fish.sh`, `keyd/` and similar steps add third-party apt repositories only where needed (ADR-0104).
3. `30_mise.sh` installs mise, then runs `mise bootstrap --only` for whichever of `packages`, `tools` and `services` report something missing.
   `--only packages` applies every `[bootstrap.packages]` entry mise has loaded, not one file's (ADR-0049).
4. The rest, including `omarchy/`, run after `30_mise.sh` and can rely on its tools.

## Rules of thumb

- Prefer a declaration to a step; write a step only for what a declaration cannot express (a daemon, a repository, per-user setup).
- A step may install a package only when a declaration cannot: it needs a repository added first, depends on hardware, or installs the installer itself.
  Today that is `30_mise.sh`, `20_fish.sh`, `keyd/keyd.sh`, `25_tailscale.sh`, `omarchy/fingerprint.sh`, and `tmux-grammar.sh`.
- `tmux-grammar.sh` installs `g++` itself: `dependencies.txt` passes names unchanged, Arch has no `g++` package (its `gcc` provides `c++`), and Debian needs `g++`.
- Gate a step on the capability it needs, not on a distro name (ADR-0044).
  A step adding an apt repository does not pin distros: it probes upstream for `ID`, then `ID_LIKE`, with the codename, and takes the first published match (`25_tailscale.sh`).
  `20_fish.sh` still branches on `ID` (ADR-0104).
- `tool remove` and a dropped declaration do not uninstall `aur:` packages; only `absent` removes, and only for `pacman:`.
- A removal by `absent` uses `pacman -R`, so orphaned dependencies stay.

## Superseded

ADR-0046 (the `packages.toml` variants driving installs through `mise bootstrap`) is replaced by ADR-0048 for installs; the variants remain the record.
The `pacman` field on a tool declaration, from ADR-0048, now lives in `tool-extras.toml` (ADR-0105).
