# Harness design rules

Doctrine for building the harness. The audit in `SKILL.md` enforces these; this
file says why they exist. A rule that cannot name the failure it prevents does
not belong here.

## R1. Agents are containers. Skills are content.

An agent is justified only by a container property: tool scoping (especially
denying Write), a model pin, context isolation where it reads far more than it
reports, parallelism, or cold-start independence. Value that is only prompt text
belongs in a skill, which delivers it without paying for a handoff.

*Failure it prevents:* role agents that differ only in domain nouns --
`backend-developer` and `frontend-developer` stamped from one template, word for
word identical apart from the stack they name.

## R2. An agent never names a domain.

Generic container, caller-supplied binding. Domain knowledge arrives through the
skill the caller names, not welded into the agent body.

*Failure it prevents:* a second domain wanting the same container has to clone
the agent file, and the isolation protocol then exists twice, free to drift.

A worked example naming a domain is fine -- `tester` cites tmux to front-load the
never-touch-live-state warning. The rule bars *binding*, not illustration: a
second domain must work without editing the agent.

## R3. Placement -- would this sentence be false in another project?

Yes, project tier. No, user tier. When in doubt, go narrower: a rule wrongly kept
local costs one duplicate later; wrongly hoisted, it is wrong everywhere
immediately.

*Failure it prevents:* a commit-style rule that forbids conventional prefixes
sitting in a user-level skill, silently wrong in every repo that uses them.

## R4. Declare with fallback.

Reference project facts by generic phrase plus a documented default. A missing
declaration yields a known fallback or an explicit stop, never a guess.

*Failure it prevents:* a generic skill dropped into a repo that declares nothing,
improvising a convention instead of asking or defaulting.

## R5. No memory on subagents.

Subagent memory is not shared with the main session, and setting `memory:`
force-enables Read, Write and Edit on that agent. Knowledge worth reading is
worth reviewing, so it belongs in a skill or a context file. If unavoidable,
`memory: project` -- committed and reviewable -- never `user` or `local`.

*Failure it prevents:* a private, unreviewed knowledge store in a container
nobody opens, and a read-only agent silently gaining write tools.

## R6. Preload only what is true on every invocation.

The `skills:` field injects a full SKILL.md at startup. Anything that varies by
domain comes from the caller instead.

*Failure it prevents:* re-welding a generic container to one domain, undoing R2
through the back door.

## R7. The name follows the thing's nature, and invocability follows the name.

Lowercase, hyphenated. Beyond that Anthropic documents no convention, so this one
is ours:

- **Agents are persons** -- `tester`, `auditor`. They do work on your behalf.
- **Skills are knowledge or actions.** Knowledge takes a noun (`delegation`,
  `tmux-config`) and sets `user-invocable: false`: there is nothing to invoke, it
  is something Claude should know at the right moment. An action takes an
  imperative (`audit-harness`, `report-issue`) and stays invocable both ways --
  you can type it, and Claude can reach for it unprompted.
- **Commands are a subset of skills.** `.claude/commands/foo.md` and
  `.claude/skills/foo/SKILL.md` both produce `/foo`; the skill form adds
  supporting files and invocation control. Write skills, not commands.

The pairing is checkable: a noun-named skill that is user-invocable, or an
imperative-named one nothing can trigger, is misfiled.

*Failure it prevents:* a knowledge skill cluttering the `/` menu with something
nobody would ever type, and an action nobody can reach because its name reads
like a topic.

## R8. A description is a trigger, not a label.

What it does, then when to use it. For an agent, also what comes back. It is the
only text loaded before the thing is chosen.

*Failure it prevents:* a skill that never fires because its description says what
it is rather than when to reach for it.

## R9. Only skills load on demand.

Context files, `.claude/rules/` and imports reach every subagent with no opt-out;
built-in `Explore` and `Plan` are the only agents that skip them, and that is not
configurable. Anything that should not be everywhere must be a skill body.

*Failure it prevents:* delegation policy shipped into every spawn, including the
agents that cannot delegate.

## R10. One copy.

The same name in two tiers is a silent override with no merge -- there is no
`extends:`, no partial frontmatter override. Fix by deleting, never by syncing.

*Failure it prevents:* three copies of one skill drifting apart, and a project
agent silently shadowing a user-level one of the same name.

## R11. A user-tier skill works in a repo that has never seen it.

No pre-existing directory, no config file, no setup step. This is what makes the
tier pluggable: a change lands once and every project has it, including one
created tomorrow.

*Failure it prevents:* a hoisted skill that assumes the repo it came from --
hardcoded paths, a `docs/` layout that does not exist yet, a reference to a skill
that was deleted.

## R12. Verify under the sandbox, not just in a terminal.

Tools that read credentials from a keyring, a socket, or the session bus behave
differently for an agent than for you. A skill that shells out to one is not
working until it has been run the way an agent will run it.

*Failure it prevents:* `gh`-dependent skills that pass by hand and fail for every
subagent, indistinguishably from the tool being broken.
