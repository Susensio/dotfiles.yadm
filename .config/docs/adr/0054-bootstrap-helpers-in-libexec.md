# ADR-0054: Install bootstrap helpers from assets into libexec instead of running them from the repo or as a mode of their step

Status: Accepted
Date: 2026-09-26

## Context

Two Omarchy bootstrap steps needed a script that something else ran later: the editor sync that ADR-0047's systemd path unit triggered, and a `mailto:` handler for a Gmail web app, which replaced HEY as the desktop mail handler.
The bootstrap ran every executable file under `bootstrap.d`, so a helper sitting beside its step would have run as a step of its own.
ADR-0047 had avoided that by making the sync a `sync` mode of `editor.sh`, one file with two entry points, which the user had never liked.
A helper in `~/bin` sat on `PATH` on every distro, including Mint, where it did nothing.
`~/.config/omarchy` was Omarchy's own directory, reseeded by `/etc/skel` and edited by `omarchy update` migrations.
Running the helper in place from the repo tied a desktop entry or a unit to the repo's layout, and the existing `10_xdg_compliance/assets/` held files a step copied into place, not programs run from there.
Writing the helper out from inside the step's own heredoc kept it out of the repo as a file and out of shellcheck.

## Decision

A helper lives in its step's `assets/` directory under the name it is installed as, non-executable, and the step copies it with `install -D --mode=755` into `~/.local/libexec/`; whatever calls it, a desktop entry or a systemd unit, names that absolute path.
The bootstrap already ran only executable files, so the missing mode bit keeps a helper from running as a step; a second rule excluding `assets/` by path was weighed and dropped as one more rule that had to agree with the first.
The checks find shell files by extension or shebang through `shfmt --find`, plus sourced fragments by their `# shellcheck shell=` directive, rather than by a `.sh` suffix, so a helper keeps its installed name and is still linted.
A shebang was rejected as the marker for sourced fragments: it read as a program to run.
`editor.sh` lost its `sync` mode to `omarchy/assets/omarchy-editor-sync`; `omarchy/mime.sh` installs `omarchy/assets/gmail-mailto`.
`~/.local/libexec` was chosen over `~/.local/bin` because nothing types these commands, and `~/.local/bin` already took mise's links and Omarchy's wrappers.

## Consequences

The installed copy is a snapshot: an edit to an asset reaches the machine only on the next bootstrap run.
A step whose helper is removed or renamed leaves the old copy in `~/.local/libexec`, removed by hand.
The source file is checked out on every machine, while only the step's own gate decides whether it is installed.
This partly reverses ADR-0047's single-file sync; its decision about the editor name and the menu writing `tools.conf` stands.
