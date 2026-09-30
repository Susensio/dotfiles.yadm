# ADR-0080: Gate Omarchy-only commands and bootstrap steps on a distro alternate, keeping capability checks for variation within Omarchy

Status: Accepted
Date: 2026-09-30

## Context

`environment.d/11_path.conf` puts `~/bin` on `PATH` on every machine, so a command that means something only on Omarchy is still visible and typed there, and a step under `bootstrap.d/omarchy/` still runs there, where it can only fail or install dead artifacts.
[ADR-0044](0044-gate-bootstrap-on-capability.md) answered the step half by making each step check for the command, path, or hardware it needs instead of a distro name.
That works, but it leaves the machine scope implicit: a step that needs no particular capability proves nothing, and a step that does must name a command whose absence happens to mean "not Omarchy", which is non-obvious — `applications.sh` shipped without a guard and installs an `Exec=omarchy-launch-or-focus-tui` launcher everywhere.

Three ways to make the scope explicit were weighed.
More per-step guards keep ADR-0044's rule and add nothing else, but leave the load on each author.
A capability gate in the bootstrap runner keyed to the directory name needs no rename, but hardcodes each domain in the runner and gives the choice no declarative home.
A yadm alternate reuses the mechanism the repo already selects declarations with (`mise/conf.d/omarchy.toml##distro.omarchy`): yadm links a file or a directory named with a `##<condition>` suffix only where the condition holds, and creates nothing when no condition matches.
[ADR-0047](0047-helix-canonical-editor-name.md) rejected a class alternate for one environment variable as a whole file for one value; the scale differs here, since one alternate scopes a command or a whole step set rather than a single setting.

## Decision

Scope is two layers.
Machine scope is a yadm alternate: an Omarchy-only command is tracked as `<name>##distro.omarchy` in `~/bin`, and the Omarchy step set is the directory `bootstrap.d/omarchy##distro.omarchy`.
yadm materialises the plain-named link only where the `distro` class matches, so the command is on `PATH`, and the steps exist, only on Omarchy.
This covers what a person or a keybinding names; a helper nothing types stays in `~/.local/libexec` ([ADR-0054](0054-bootstrap-helpers-in-libexec.md)).
Variation within that scope stays [ADR-0044](0044-gate-bootstrap-on-capability.md)'s: each step still checks for the command, path, or hardware it needs, because Omarchy's command set changes across `omarchy update` and `omarchy dev link` moves `OMARCHY_PATH`.
The bootstrap runner runs no file whose path carries `##`, so the alternate directory is never run as steps and is reached only through its materialised link.
Placing an item inside the alternate is the claim that it is Omarchy-only.

## Consequences

`applications.sh` and its successors need no guard to prove Omarchy, only guards for variation within it.
The tracked path carries the `##distro.omarchy` suffix while the machine-visible path keeps its plain name; docs and keybindings name the machine-visible path, and the generated link is excluded from git.
Membership is maintained by review at that boundary: a portable item placed in the alternate silently stops existing on other machines.
The runner's step finder excludes `##` paths, which also closes a latent double-run for any `##` directory, since the link and the real directory would both be walked.
A `~/bin` command's alternate sits beside its link, so its `##` name is a completion candidate in that directory; the yadm `alt` directory is the alternative if that becomes irksome.
This refines ADR-0044 rather than reversing it: that record keeps governing steps within the set.
