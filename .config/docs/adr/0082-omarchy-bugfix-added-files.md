# ADR-0082: Install files an Omarchy PR adds into the user's tree from the bugfix step, instead of patching them into the package's paths

Status: Accepted
Date: 2026-10-03

## Context

[ADR-0057](0057-omarchy-bugfix-patch-steps.md) carried each upstream Omarchy PR as a patch to files the package already shipped.
Omarchy PRs #7446 and #10542 also added files: a desktop entry and three commands.
A patch creating them under `/usr` would have left files pacman did not own at paths a later package would ship, and pacman refuses to install over such files, so the update that merged the PR would fail.
Three routes were weighed.
Fetching the PR's diff at bootstrap was rejected: it would apply whatever the author last pushed, unreviewed and under `sudo`, needed the network, and PR diffs did not always apply to the installed release.
Tracking the copies in `~/bin/overrides` was rejected: that directory held hand-written overrides, and untracked copies there would have shown in `yadm status`.
Writing them where Omarchy's own user-level copies go, `~/.local/bin` for commands and `~/.local/share/applications` for desktop entries, kept them on the session `PATH` and the desktop's search path without root.
`~/.local/bin` already held mise's links and Omarchy's wrappers ([ADR-0054](0054-bootstrap-helpers-in-libexec.md)); `omarchy-remove-preinstalls` removed only named tools there, and mise pruned only its own broken links.

## Decision

A file an Omarchy PR adds is stored verbatim in the bugfix step's `files/` directory and installed by the `install_omarchy_file` helper into the user's tree, never under `/usr`.
Edits to files the package ships still go through ADR-0057's patch helper.
When the package ships the same path, the helper removes the installed copy if it still matches the stored file, warns that the step can be dropped, and keeps a locally edited copy.

## Consequences

`omarchy update` never conflicts with a carried file, and the packaged file takes over without manual cleanup.
A command in `~/.local/bin` shadows a packaged one only while both exist, which the removal rule keeps to the run before the step notices.
After removal the step is silent, like an ADR-0057 step whose fix shipped, so it still has to be deleted by hand.
A rejected PR leaves its copies installed until the step and the files are removed by hand.
