# ADR-0096: Derive the maintenance watch list from tracked links and keep the agent out of the update hook

Status: Accepted
Date: 2026-10-21

## Context

Keeping this setup current meant noticing, by hand, when an upstream item it waited on moved: a bugfix step's PR merging (ADR-0057, ADR-0082), a pi package fix landing, a backlog entry's "once it lands" coming true, a reply on a PR of the user's.
About forty distinct GitHub issue, PR and discussion links already sat in tracked files, each beside the line that depended on it, and `docs/STATE.md` had sections waiting on two PRs that had already closed.
Local drift had the same problem: `omarchy update` migrations write into tracked files, and the bootstrap's stale-patch warnings scrolled past in the update terminal.

A tracked watch file, one entry per awaited item with what to do when it resolves, was considered and rejected: each entry would repeat a link that already sat beside its dependent line, and editing or deleting that line would not update the watch.
Running an agent from the post-update hook was rejected because it would spend tokens on every update, whether or not anything had changed, and could hold up the update.
Unread notifications were dominated by `ci_activity` threads, one per workflow run.

## Decision

`~/bin/maintenance` reports and never acts.
It greps tracked files for GitHub issue, PR and discussion links, skipping ADRs, the `report-issue` skill's past issues, and vendored `.orig` copies, and asks GitHub, in one GraphQL request, which have closed or merged, listing each with its locations.
The same request finds the user's open PRs with requested changes, conflicts or failing checks; unread notifications other than `ci_activity` come from a second request.
Locally it lists uncommitted tracked files, unpushed commits, warnings from the last bootstrap run, failed systemd units and `.pacnew` or `.pacsave` files.
`yadm bootstrap` copies its stderr to `~/.local/state/yadm/bootstrap.log` so those warnings outlive the terminal.

The `/maintenance` pi prompt runs the report and judges each finding in context, since the same closure can mean deleting a step, waiting for a release, or nothing; it proposes and asks, and commits, posts or marks notifications read only on approval.

The post-update hook runs `maintenance --new`, which prints only items that no earlier `--new` run printed and records them, and sends a notification only when there is one; clicking it opens `pi /maintenance` in a floating terminal.

## Consequences

A link added beside a dependent line is watched with no other step, and deleting the line stops watching it; a thread to follow with nothing depending on it is subscribed to on GitHub and arrives as a notification.
Every link counts as awaited, so one kept as history or context is reported once it closes, and the prompt has to say it needs nothing.
The full report keeps listing a resolved item until its link is edited out, such as a backlog entry kept after its issue was closed as not planned; the hook notifies about it once.
`--new` compares whole item lines, so an item whose text changes, such as a notification with new activity on a later day, notifies again; activity on the same day as the last notification does not.
The seen list in `~/.local/state/maintenance/seen` is local and keeps its newest 2000 lines; an item that disappears and comes back unchanged does not notify again.
When GitHub is unreachable the report says so under `Skipped`, while `--new` stays silent about it and catches up on the next run.
The bootstrap log holds only the last run, so a warning that fires once, such as a carried file removed because the package now ships it, is lost if another bootstrap runs before anything reads the log.
The bootstrap's stderr is a pipe rather than the terminal, so a step that checks for a terminal on stderr behaves as if run without one.
