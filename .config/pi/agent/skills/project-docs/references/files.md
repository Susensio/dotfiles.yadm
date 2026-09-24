# Standard project records

These are fallback boundaries for this user's own repositories.
An established repository convention takes precedence.
A pointer in repository guidance may identify each unusual record, but detailed boundaries stay here rather than being duplicated into every project.

## `README.md` — identity and use

Describe what the project does and what someone needs to use it.

Earned when there is a reader who uses the project without changing it.

Boundary: required internal behavior belongs in `docs/SPEC.md`, ordered future work in `docs/ROADMAP.md`, and architectural reasoning in an ADR.

## Repository guidance — local surprises

Keep only facts and conventions an agent would otherwise get wrong while changing this repository, plus pointers needed to find project records.
Do not restate commands or facts already declared by manifests, CI, or tooling.

Earned when the repository has a non-obvious constraint or convention.

Boundary: orientation for users belongs in the README; conditional procedures belong in skills or focused documentation.

## `docs/SPEC.md` — required behavior

Record what the system must do, independently of implementation order.

Earned when requirements can no longer remain clear inside the README.

Boundary: sequencing belongs in `docs/ROADMAP.md`; rationale for a durable choice belongs in an ADR; a temporary implementation brief belongs in `.scratch/`.

## `docs/ROADMAP.md` — ordered milestones

Record phases, milestones, or releases whose entries contain smaller work.
The user owns roadmap intent; agents do not change it unless asked.

Earned when an ordered roadmap or TODO section outgrows the README.

Boundary: one uncommitted unit of work is a backlog item, however large it appears.
A roadmap item no longer intended returns to the backlog rather than remaining stale.

## `docs/BACKLOG.md` — open work

Record bugs, debt, and ideas that nobody has committed to implement.
Use the project's format when one exists; otherwise prefer one searchable entry per item with indented reproduction details, links, or prior attempts.

Earned when open work outgrows the README's TODO section.

Boundary: accepted or started work leaves the backlog for `docs/STATE.md`.
A defect with one obvious source location should use the project's in-code marker convention instead of a duplicate index entry.

## `docs/STATE.md` — unfinished committed work

Record only the current handoff state for accepted or started work that must survive a session boundary: what remains, what changed, and what was verified.

Earned when work becomes committed but cannot finish in the current session.

Boundary: proposals remain in the backlog, while decision rationale remains in its ADR.
Edit this file to reflect current truth; do not append a historical log.
Remove completed sections, and delete the file when no unfinished state remains.

## `docs/adr/` — durable decisions

Number records as `NNNN-short-slug.md` and use the `adr` skill to decide when one is warranted.

Earned by a durable choice between real alternatives whose reasoning has no better local home.
ADR creation is an event, not document overflow.

Boundary: live rules remain in the file that governs them; an ADR records why the choice was made at that moment.

## Procedure documents

Put a procedure under `docs/` when a person will also execute it, such as deployment or release steps.
Use a focused name and make the corresponding skill or repository guidance point to it when routing would otherwise be unclear.

Boundary: agent-only execution instructions belong in a skill or repository guidance.

## `.scratch/` — temporary material

Keep disposable scripts, captured output, dumps, and one-task briefs here.
Add it to the repository's ignore mechanism before creating temporary material.

Earned when the first temporary repository-local file is needed.

Boundary: nothing here is a source of truth.
Move durable information to its proper record or delete it when the task finishes.
