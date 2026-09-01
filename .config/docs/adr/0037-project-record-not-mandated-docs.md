# ADR-0037: Split the project record skill into finding one and creating one, instead of mandating four files everywhere

Status: Accepted
Date: 2026-08-31

## Context

ADR-0033 drew the line between `leader` and the default session as documentation discipline, and pointed `leader` at the `project-docs` skill to supply it.
That skill answered one question — where a piece of information goes — with one table naming `docs/PLAN.md`, `docs/BACKLOG.md`, `STATE.md` and `.scratch/`.

Five working modes were named against it: starting a project, continuing one, contributing to a community project, small edits in one's own projects, small edits elsewhere.
The table fitted the first two.
In the other three it was wrong in two different directions.

`leader` autoloads the skill, and since `skills:` does not fire on `--agent`, `skills-on-launch.py` injects the body at startup, so the whole table reached every project session including a community repository where none of those filenames applied.
Worse than the tokens, the skill read as a mandate to create them: nothing in it distinguished a repository whose conventions were the user's to set from one where a new top-level file is a change to someone else's project.
That also failed the tier test in the `harness-design` skill outright, which requires a user-tier skill to work in a repository that has never seen it.

Two defects surfaced while probing the change rather than from reading it.
A ladder step conditioned on the project keeping nothing meant a partially-documented project could never reach its own defaults: this repository kept `docs/BACKLOG.md` and no `docs/PLAN.md`, so a session looking for where intent goes found plenty kept, skipped the step, and would have invented a filename.
And `creating.md` mandates ignoring `STATE.md`, while `rg` and `fd` skip ignored files by default and `CLAUDE.md` steers agents toward both — so the one file whose purpose is cross-session continuity was invisible to the discovery step meant to find it.

Three alternatives were weighed and discarded.

Keeping one skill and gating the table on whose repository it is was rejected because the gate does not reduce what loads: a community session still pays for filenames it must not use, and the hedging spreads through every line.

Folding the defaults back in as a reference file behind a pointer was measured rather than argued: a separate skill costs its description in every session's roster, a reference file costs nothing there. The difference was about 250 characters, which did not justify undoing a split already validated on names, wiring and load path.

Writing the conventions into the target project's `CLAUDE.md` at bootstrap time was adopted and then reversed within the session. Declaring four files that do not exist repeats, one level up, the failure the skill already names for an empty file: it advertises a record that is not there.

## Decision

`project-docs` is split by trigger.
`project-record` holds what is true in any repository — a ladder that reads what the project declares about itself, then what it visibly keeps, then falls through to defaults only where the project keeps no home for that kind and its conventions are the user's to set.
`bootstrap-project-docs` holds the user's own filenames and the conditions that earn each, and loads only when invoked.
`leader` autoloads the first and owns keeping the record current; the second reaches a session through the ladder's third step.

Where a repository's conventions belong to someone else, a finding travels in the report or through whatever that project uses to propose a change, and no file is created in its tree.

`README.md` is the destination for what a project is and how someone uses it, and is the one file earned on day one, written before the code.
`docs/PLAN.md` is demoted to milestones, earned only once they outgrow the README.
Anti-goals were dropped from its template rather than relocated: the user does not think in those terms, and a section written to satisfy a template is not a record.

A file is named in its project's own `CLAUDE.md` in the same step that creates it, never before — one line giving its location and the kind of thing it holds, never its format. That line is what a later session reads, since `CLAUDE.md` loads every turn for every agent in the repository while a file's own boundary line costs a read to reach.

## Consequences

One architecture covers all five modes, and the community-repository case degrades toward reporting rather than toward writing in someone else's tree.

The split costs `bootstrap-project-docs`'s description in every session's roster, including repositories where it can never fire. That was measured at roughly 250 characters and accepted as the price of the `/` entry and of one concept per container.

The default session gained no record duty. `project-docs` is autoloaded only by `leader`, so elsewhere it fires on a description match or not at all, and nothing in `CLAUDE.md` mandates writing anything down. During a prototype this is survivable because the user is in the conversation; the loss is decisions settled while prototyping, which is what the `adr` skill exists for and which nothing currently triggers. Whether that duty needs a home is left open.

The `PLAN.md`, `STATE.md` and `.scratch/` rows are unvalidated. Across this repository's whole history none of the three was ever created, but a dotfiles repository has no build, no roadmap and no prototyping phase, so that is weak evidence about a software project. The first real project settles it: whether any of the three gets reached for, or worked around.

Whether README-first survives contact is open for the same reason. If it holds, the `docs/PLAN.md` row narrows further; if the README turns out to be the wrong place for intent, the row returns to what it was.

`STATE.md` remains gitignored and remains unsettled. Its justification claims it is too transient to version while also mandating a file for it, and those pull apart; the question of whether it earns a mandate at all was deliberately not answered here.

Enforcement is convention. Nothing checks that a created file gets its `CLAUDE.md` line, that the ladder is walked before a file is added, or that a community repository is left alone — each rests on the prose being read.
