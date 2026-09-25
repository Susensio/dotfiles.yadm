# ADR-0049: Declare Omarchy's preinstalls in mise and trim their launchers in bootstrap, instead of running omarchy-remove-preinstalls

Status: Accepted
Date: 2026-09-25

## Context

Omarchy shipped preinstalled packages, webapp and TUI launchers, and mise wrappers in `~/.local/bin` for agent CLIs; only some were wanted.
Its `omarchy-remove-preinstalls` removed all of them behind a `gum confirm` prompt and created `~/.local/state/omarchy/preinstalls-removed`, which Omarchy's migrations and Hyprland bindings read as the opt-out.
It also ran a blanket `rm -f` over `~/.local/bin/{claude,codex,gh,agy,opencode,pi,…}`, the paths where ADR-0007 linked our own mise tools, so running it after `mise.sh` deleted those links; its counterpart, `omarchy-install-preinstalls`, rewrote wrappers over them.
It removed every launcher, so it could not run again once launchers of our own were added.

Weighed and rejected: calling the upstream remover once, guarded by its marker, which still hit our links and prompted; auto-answering its prompt through `GUM_CONFIRM_TIMEOUT`, a hack that declined without a terminal; keeping the package list in the script with `omarchy-pkg-drop`, which mise's pacman `state = "absent"` (mise v2026.9.2) made declarative.
`mise bootstrap --only packages` was also found to select steps, not files: it applies every `[bootstrap.packages]` entry of every loaded config, so a list scoped by config file could only be had by pointing `MISE_GLOBAL_CONFIG_FILE` at it alone.

## Decision

`mise/conf.d/omarchy.toml##distro.omarchy` declares every Omarchy preinstall, the kept ones `latest` and the rest `absent`, and `tldr`, which conflicted with tealdeer and had been removed by a `pre-packages` hook.
Omarchy's `/etc/os-release` said `ID=omarchy`, `ID_LIKE=arch`, so the file is Omarchy-only, and the Arch tool variant became `packages.toml##distro_family.arch` to match both Arch and Omarchy.
`yadm/bootstrap.d/mise.sh` runs `mise bootstrap --only packages,tools` itself, as machine-wide state, rather than `tool bootstrap`, which was removed.
`yadm/bootstrap.d/omarchy/preinstalls.sh` repeats the upstream remover's non-package steps once, guarded by the same marker: it removes the webapp and TUI launchers and only the wrappers Omarchy wrote (a regular file with `mise use -g`, or Hermes' through `omarchy-install-hermes-cli --owns`), then creates the marker; on every run it reinstalls the launchers kept.
`omarchy/extensions/omarchy-menu.jsonc` hides the menu's Install and Remove › Preinstalls entries.

## Consequences

No prompt, and our links in `~/.local/bin` are never touched; nothing kept is removed and reinstalled.
The lists are ours: a preinstall a later Omarchy adds stays until it is listed, and a new wrapper name stays until the loop names it.
`absent` is enforced on every bootstrap, so a package reinstalled by hand is removed again unless its entry changes.
`mise bootstrap packages apply` removes with `pacman -R`, not `-Rns`, leaving orphaned dependencies.
The scripts were checked against Omarchy 4.0.4 and its development branch, `quattro`, not run on a machine.
Running `omarchy-remove-preinstalls` or `omarchy-install-preinstalls` by hand undoes this; the menu no longer offers them.
