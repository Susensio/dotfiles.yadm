# ADR-0031: Track this repo's defects in a local backlog file

Status: Accepted
Date: 2026-08-20

## Context

Defects here were routed two ways: `BUG:` and `TODO:` markers on the offending line, and `gh issue create --repo Susensio/dotfiles.yadm` for anything with no single line to mark or worth tracking to closure.
The marker half works.
The issue half was never used much, and the reasons are structural rather than incidental.

An issue lives on a server this repo does not otherwise depend on.
Filing one needs network and an authenticated `gh`, which under the agent sandbox is a different code path from filing one by hand.
The fix and the record of the fix land in two places, so closing the issue is a second step that gets skipped.
And a config repo's defects are mostly small, local, and interesting to exactly one person; the issue tracker's real value -- other people finding, discussing and subscribing to a report -- does not apply.

The alternative considered and rejected was one file per issue in a directory, on the argument that a bullet cannot hold a repro.
It buys per-item history at the cost of a directory listing that has to be read to see what is open.

## Decision

Anything broken with no single line to mark, or worth tracking to closure, goes in `docs/BACKLOG.md`.
One entry per line -- priority, area, one sentence -- with an indented block under it where an entry needs a repro, a link, or what was already tried.

`BUG:` and `TODO:` markers are unchanged: they mark the line that is wrong, and the backlog holds what no single line can carry.
The `report-issue` skill keeps its job of filing upstream, against tmux and the other projects this setup consumes, never against this repo.

## Consequences

A defect and its fix land in one commit and one diff, so the entry cannot outlive the fix by being forgotten in a second system.
Works offline, and identically for an agent under the sandbox and for a person in a terminal.
`rg '^- ' docs/BACKLOG.md` is the whole list.

Open work is written in two places and read in two: this file for what has no single line, and `rg -n 'BUG:|TODO:'` for what does.
The backlog's header names that search rather than holding a copy of its output.

A generated index at the foot of the backlog was built and then removed.
It refreshed the marker half on a hook, so that opening one file showed everything without knowing the search.
Removed on three counts: the machinery came to a script, a hook, and a relevance gate to keep the per-edit cost tolerable, against a payload of two markers; hand-copying the markers instead would have put a second, drifting copy of each in the file; and the script's `grep` fallback silently indexed several hundred TODOs out of the vendored grammars under `~/.config`, which `rg` ignores correctly and `grep` cannot be told to.
Worth revisiting only once the marker count is high enough that searching for them is the awkward part.

Accepted limitation until then: a person opening `docs/BACKLOG.md` sees what has no single line, and has to run the search in the header to see the rest.

The indented block is the escape valve for the entry that needs more than a line, and it has a ceiling: an entry that outgrows it is a decision, and belongs in an ADR instead.
That boundary is a judgment, so the backlog will sometimes hold something that should have been recorded here.

Cost: no per-item history, no author, no discussion thread, no way for anyone else to report anything.
The last is the one that would bite -- if this repo ever acquires a reader who is not its author, they have no place to file, and this decision is the one to revisit.

Merge conflicts move from nowhere to one file, since every branch that finds a defect appends to the same three sections.
Appending to the end of a section keeps them trivial.
