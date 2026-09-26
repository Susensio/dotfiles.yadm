# ADR-0056: Make bootstrap steps check before acting, silent and sudo-free when nothing changes, instead of reapplying everything or a shared sync helper

Status: Accepted
Date: 2026-09-26

## Context

The bootstrap from [ADR-0005](0005-idempotent-directory-dispatched-bootstrap.md) was idempotent in outcome but not in cost.
A rerun with nothing to do called `sudo install --compare --verbose` for every `/etc` asset, `sudo systemctl enable`, `usermod` and `setfacl`, so it prompted for a password or fingerprint each time.
It rewrote and reloaded the keyd and editor-sync user units, reinstalled every Omarchy web app launcher, reset MIME defaults, asked GitHub for the latest Nerd Fonts release, and printed a line per step.
`mise bootstrap` removed and reinstalled tealdeer on every run: tealdeer provides `tldr`, so `pacman -Q tldr` answered for it and ADR-0049's `absent` entry for Omarchy's tldr matched it.
The goal was a bootstrap cheap and quiet enough to rerun at will, and later from a yadm hook after every pull.

A shared `~/bin/sync-file` was written and dropped: it compared content and mode and chose sudo by the target directory's permissions, but it sat on `PATH` for the bootstrap's sake only, and the inline check it replaced was one line.
Tracking the user units in `~/.config/systemd/user` instead of installing them was weighed: that directory also held units and `*.wants` links that Omarchy and `systemctl enable` wrote, which tracking it would have pulled in, several of them Omarchy-only.

## Decision

Every step checks the state it wants before acting, as the user: `cmp -s` before `install`, `systemctl is-enabled`/`is-active` before `enable`, `id`, `getfacl` and `grep` before `usermod`, `setfacl` and `sed`, and a `.desktop` or `mimeapps.list` entry before reinstalling a launcher or setting a default.
`sudo` runs only behind a failed check, so a rerun with nothing to do never prompts.
A step prints only what it changes; `install --verbose` supplies that line.
`yadm/bootstrap` prints nothing of its own, and `DEBUG=1` shows each step's duration.
User units are assets under their step, written with `%h` rather than an expanded home, installed when they differ, with `daemon-reload` and a restart only then; keyd's step moved into `bootstrap.d/keyd/` to hold them.
A network check runs at most weekly, keyed on its version file's mtime.
`mise bootstrap` runs with `--quiet`, and its `system-install` postinstall task is marked `quiet`.
Omarchy's `tldr` is removed by a `pre-packages` hook that checks the answering package's name, replacing ADR-0049's `absent` entry for it.

## Consequences

A rerun is silent and prompt-free, which makes running it from a yadm hook plausible.
Each step carries its own check, so a new step that forgets one is noisy again and nothing enforces the rule.
`/etc/sudoers.d` is unreadable without root, so `sudo.sh` checks only that its file exists: an edit to that asset needs the installed file removed by hand.
An asset whose mode changes while its content does not is not reinstalled.
A Nerd Fonts release waits up to a week, and a hand-edited launcher or MIME default that still exists is left alone.
