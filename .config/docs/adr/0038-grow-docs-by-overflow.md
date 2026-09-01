# ADR-0038: Grow project docs by overflow instead of adopting a schema

Status: Accepted
Date: 2026-09-01

## Context

ADR-0037 split the project record skill by trigger -- `project-record` to find where a project already keeps things, `bootstrap-project-docs` to create files where the conventions were the user's to set.
It left four questions open in its own Consequences, and an audit of the harness reopened them together with a defect it had introduced.

The defect was duplication.
Both halves needed a taxonomy of kinds to be usable, so both carried one, and they had already drifted: `project-record` had no row for the plan, `bootstrap-project-docs` had none for a defect with one wrong line or for a settled decision.
`leader` autoloaded only the first, so it carried a rule about `docs/PLAN.md` in its own body while the skill it loaded did not know a plan existed.

Underneath that sat a framing error.
The two skills partitioned on user-facing versus agent-facing, and that axis does not partition: an agent reads user-facing docs, so the sets nest rather than divide, and every nested set produced the overlap the split was meant to remove.
Trying to name a category of agent-only *content* failed -- every candidate turned out to be something a new human developer would want too.
What is genuinely agent-only is that an agent will not go looking, so the content has to arrive, which is a delivery property and not a content one.

The `earned when` conditions were events rather than volumes -- "a session has actually been lost and the reconstruction cost was felt" -- which nobody recognises at the moment it happens, so the ladder could never be climbed deliberately.

Four alternatives were weighed and discarded.

Merging the two skills back into one was rejected on the ground it was proposed: the duplication is fixable in place by giving one skill the kinds and the other the filenames, so merging solves nothing the cheaper change does not, while reversing a split validated on names, wiring and load path.

Hiding the second skill with `disable-model-invocation: true` was adopted and reversed within the session.
It removes the description from the roster and leaves only `/name`, which would have made every doc-structure decision a manual invocation -- the opposite of the autonomy wanted in the user's own repositories, where the point is that nobody is watching.

Restricting `.claude/` to routing only was rejected as contradicting the `harness-design` skill, which already holds the better rule: a dual-audience procedure keeps its source of truth in `docs/` with the skill pointing at it, and a procedure only Claude runs stays whole in the skill.

Treating `STATE.md` as settled either way was rejected on the evidence.
Research found no practitioner account of adopting such a file and abandoning it, and none of sustained success, so the file was withdrawn from the schema on indirect evidence rather than declared wrong.

## Decision

Records grow by overflow.
A concern gets its own file when it can no longer be stated where it lives -- sometimes a section graduating, sometimes the whole document failing to contain something.
The filenames below are names for common overflows, so they stay consistent across this user's projects; they are not a schema to adopt, and a project creates none of them until something has actually overflowed.

`README.md` is earned when there is a reader who uses the project without changing it.
Where use and change are the same audience, one file serves both and the README is not earned -- which is why this repository has none and needs no exemption to explain it.
A project's own `CLAUDE.md` is earned by the first surprise, not on day one; one restating what `package.json` already says costs every turn and teaches the model to discount the lines beside it.
Neither carries an index line pointing at the other.

The root holds entry points and nothing that overflowed, so location answers whether a thing overflowed.
`docs/SPEC.md` holds what the system must do, and overflows from a README that cannot hold the behaviour -- it answers to no section, which is why it was missed when overflow was read as sections graduating.
`docs/ROADMAP.md` replaces `docs/PLAN.md`: the name the rest of the world uses is the one the discovery ladder finds in other people's repositories, and "plan" reads either as milestones or as an ordered task list, the second of which is the backlog under another name.
`STATE.md` is withdrawn.

A roadmap entry contains other work; a backlog entry is work.
Phases and large features sit together in a roadmap because both are containers, differing only in size, and nothing is ever promoted between the two files because a leaf does not become a container.
The boundary is a judgement and is left one: an entry filed in the wrong file is still found and still done, so it does not earn a mechanism.

Where the repository is not the user's, no file is created in it.
That is decidable and gets a hook rather than prose alone: creating a record file in a repository whose remote is not the user's, or writing the roadmap in any repository, earns a once-per-agent nudge, with the prose stating the same rule for the agent that should never reach the hook.
An `upstream` remote means the repository is someone else's even where `origin` is the user's fork; no remote at all means it is theirs to set.

`project-record` is renamed `project-docs` and owns the kinds.
`bootstrap-project-docs` is renamed `grow-project-docs` and owns the filenames, the overflow rule and the boundary each file holds.
`leader` loses its own rule about the plan, which now arrives through the skill it already loads.

## Consequences

The taxonomy has one owner, so the drift ADR-0037 introduced cannot recur by the same route.

This supersedes ADR-0031 on the backlog's format only; its decision to keep defects in a local file rather than GitHub issues stands unchanged.
Entries lose the priority field and the `Bugs`/`Tech debt`/`Explorations` sections.
What is left is one line each, an optional area prefix, and the indented block, which is the part that pays -- a subagent reads "tried this, no change" and does not repeat the dead end.
The cost is the merge locality ADR-0031 bought by having three sections to append to; with one list, concurrent branches append to the same place.
That is worth revisiting if conflicts appear, and is not expected to at this repository's volume.
The gain is that adding an entry needs no classification decision, and every mandatory field is a reason to not write the finding down at all.

A record file no longer explains itself in its own first lines, which drops that rule from `grow-project-docs`.
The project's own `CLAUDE.md` carries one line per file -- where it sits, what it holds, who writes it -- and that is the copy that does the work, since it loads before anything has been opened.
ADR-0031's consequence that the backlog's header names the `rg` search had already rotted: the live file carries no such line and the search sits in this repository's `CLAUDE.md`.
The asymmetry this creates is deliberate and stated in `project-docs`: other people's files sometimes declare their own boundary and that declaration governs, while this user's will not.

`STATE.md` is withdrawn without being declared wrong.
The three rules its users converge on -- gitignored, rewritten rather than appended, blockers and dead ends only -- match what `bootstrap-project-docs` already specified, so the shape was right and only the mandate was not.
What removed it was the absence of evidence for it plus two findings against: an instruction file edited mid-session is not reliably re-read, which is worse for a file whose purpose is to change, and the harness is growing an on-disk multi-session task list that does the same job.
If a session is ever genuinely lost in a way the record does not cover, this is the row to reconsider first.

Whether a compaction instruction should steer what a summary preserves is left open.
`PreCompact` cannot do it -- it accepts no `additionalContext` and can only cancel a compaction -- so the candidate slots were `CLAUDE.md` and an output style, and the probe that would have settled which could not run: a throwaway `CLAUDE_CONFIG_DIR` has no credentials, and authenticating one needs a token or an interactive login the test could not obtain. The claim that `CLAUDE.md` reaches the summarizing model is Anthropic's recommendation but remains inference from delivery mechanics, so nothing was written on it.

The `SPEC.md`, `ROADMAP.md` and `.scratch/` rows remain unvalidated, as ADR-0037 said of their predecessors and for the same reason: this repository has no build, no roadmap and no prototyping phase, so its history is weak evidence about a software project. Reasoning from this repository's own file list to what a software project needs was tried here and was circular; the first real project settles it instead.

Enforcement remains thin. The hook covers creating a record file in someone else's repository, and writing the roadmap in any repository. Nothing checks that a created file gets its `CLAUDE.md` line, that overflow happened before a file appeared, or that the container-versus-leaf boundary was applied -- each rests on the prose being read.
