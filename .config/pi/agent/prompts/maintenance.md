---
description: Review the maintenance report — upstream closures, GitHub activity, local drift — and propose the follow-up for each
---
Run `maintenance` and work through its report in `~/.config` (ADR-0096).
It reports, it never judges: a finding is a line to read in context, not an instruction.
Run it without `--new`, which is the update hook's notifier and records what it printed.

Each two-space line is one item; the four-space lines under it are its locations or detail.
Exit 1 only means there are findings; a `Skipped` section means that source was not checked, so say so instead of reporting it clean.

## Resolved upstream

A link in a tracked file whose issue, PR or discussion has closed or merged.
Read every location with its surrounding lines and decide what the closure means there; the same event asks for different things:

- A bugfix step or carried file whose PR merged (ADR-0057, ADR-0082): the fix only matters once it ships, so compare the installed package against the PR before proposing to delete the step, its patch and its files; if it has not shipped yet, say which release to wait for.
- A PR closed unmerged: the local patch still carries the fix, so propose the follow-up — a new PR, a note, or dropping the patch if the problem is gone.
- A `docs/BACKLOG.md` or `docs/STATE.md` entry waiting on it: apply its own "once it lands" instruction, or rewrite the entry when the closure did not deliver, such as closed as not planned.
- A link kept as history or context: nothing to do; say so in one line.

Read the thread (`gh pr view <url> --comments`, `gh issue view <url> --comments`) whenever the closure reason or a last comment changes the answer.

## Needs you

Unread GitHub notifications, CI runs excluded, and open PRs of the user's with requested changes, conflicts or failing checks.
Read each thread from where the user last spoke and say whether it needs a reply, a code change, or nothing.
Draft a reply in the user's voice when one is due.

## Local

- `uncommitted`: separate what an `omarchy update` migration wrote (`docs/omarchy.md`, "Omarchy writes into tracked files") from the user's own edits in progress, using `yadm diff <path>`; for a migration's edit, propose keeping it, reverting it, or teaching the bootstrap to undo it.
- `bootstrap`: a warning from the last bootstrap run, kept in `~/.local/state/yadm/bootstrap.log`; a stale patch names its step, whose comment links the PR to check.
- `unpushed commits`: mention, nothing more.
- `failed unit` and `config to merge`: find the cause from the journal or the `.pacnew` diff and propose the fix.

## Report

One list, most urgent first: the item, what it means here, and the proposed action as an exact edit, a command, or a draft reply.
Then ask which to carry out.
Commit, post to GitHub, mark a notification read (`gh api -X PATCH notifications/threads/<id>`), or delete a file only for an item the user approved.
Work the user defers goes into `docs/BACKLOG.md`, or `docs/STATE.md` when it is already committed to (ADR-0041).
