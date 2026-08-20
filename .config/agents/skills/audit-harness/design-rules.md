# Harness design rules

Doctrine for building the harness.
The audit in `SKILL.md` enforces these; this file says why they exist.
A rule that cannot name the failure it prevents does not belong here.

Each rule states the current conclusion and the failure it prevents, and stops there.
The investigation behind it -- what was probed, which hypothesis died -- belongs in the commit that changed the rule, or in an ADR when a decision was reversed.
Provenance read here on every audit costs more than it informs; `git log -p` still has it when the rule looks wrong.

## R1. Agents are containers. Skills are content.

An agent is justified only by a container property: tool scoping (especially denying Write), a model pin, context isolation where it reads far more than it reports, parallelism, or cold-start independence.
Value that is only prompt text belongs in a skill, which delivers it without paying for a handoff.

*Failure it prevents:* role agents that differ only in domain nouns -- `backend-developer` and `frontend-developer` stamped from one template, word for word identical apart from the stack they name.

## R2. An agent never names a domain.

Generic container, caller-supplied binding.
Domain knowledge arrives through the skill the caller names, not welded into the agent body.
A worked example naming a domain is fine -- `tester` cites tmux to front-load the never-touch-live-state warning.
The rule bars *binding*, not illustration: a second domain must work without editing the agent.

*Failure it prevents:* a second domain wanting the same container has to clone the agent file, and the isolation protocol then exists twice, free to drift.

## R3. Placement -- would this sentence be false in another project?

Yes, project tier.
No, user tier.
When in doubt, go narrower: a rule wrongly kept local costs one duplicate later; wrongly hoisted, it is wrong everywhere immediately.

*Failure it prevents:* a commit-style rule that forbids conventional prefixes sitting in a user-level skill, silently wrong in every repo that uses them.

## R4. Declare with fallback.

Reference project facts by generic phrase plus a documented default.
A missing declaration yields a known fallback or an explicit stop, never a guess.

*Failure it prevents:* a generic skill dropped into a repo that declares nothing, improvising a convention instead of asking or defaulting.

## R5. No memory on subagents.

Subagent memory is not shared with the main session, and setting `memory:` force-enables Read, Write and Edit on that agent.
Knowledge worth reading is worth reviewing, so it belongs in a skill or a context file.
If unavoidable, `memory: project` -- committed and reviewable -- never `user` or `local`.

*Failure it prevents:* a private, unreviewed knowledge store in a container nobody opens, and a read-only agent silently gaining write tools.

## R6. Preload only what is true on every invocation.

The `skills:` field injects a full SKILL.md at startup.
Anything that varies by domain comes from the caller instead.

*Failure it prevents:* re-welding a generic container to one domain, undoing R2 through the back door.

## R7. The name follows the thing's nature, and invocability follows the name.

Lowercase, hyphenated.
Beyond that:

- **Agents are persons** -- `tester`, `auditor`.
- **Knowledge skills take a noun** -- `delegation`, `tmux-config` -- and set `user-invocable: false`.
  There is nothing to invoke; it is something Claude should know at the right moment.
- **Action skills take an imperative** -- `audit-harness`, `report-issue` -- and stay invocable both ways.

Commands are a subset of skills and add nothing a skill lacks.
Write skills.

The pairing is checkable: a noun-named skill that is user-invocable, or an imperative-named one nothing can trigger, is misfiled.

*Failure it prevents:* a knowledge skill cluttering the `/` menu with something nobody would type, and an action nobody can reach because its name reads like a topic.

## R8. A description is a trigger, not a label; a body is instructions, not commentary.

The description says what it does, then when to use it, and for an agent what comes back.
It is the only text loaded before the thing is chosen.

The body states the rule and stops.
An agent following an instruction does not need to know which mechanism failed to enforce it -- explanations of how the harness behaves belong in this file, not scattered through the things it governs.

The two have different readers: the description is read by the caller choosing whether to reach for this at all, the body by the thing itself, executing.
A fact that does both jobs belongs in both, worded for its reader -- a read-only agent advertises `Read-only: it judges, never changes` to the caller, and states the contract with its loopholes to itself (R13).
Two readers, one copy each, is not the duplication R10 forbids.
The exemption is per reader, not per file: two copies serving the same reader is R10, however far apart they sit.

*Failure it prevents:* a skill that never fires because its description says what it is rather than when to reach for it; and agent bodies that grow into essays about the harness, paid for on every spawn.

## R9. Only skills load on demand.

Context files, `.claude/rules/` and imports reach every subagent with no opt-out; built-in `Explore` and `Plan` are the only agents that skip them, and that is not configurable.
Anything that should not be everywhere must be a skill body.

*Failure it prevents:* delegation policy shipped into every spawn, including the agents that cannot delegate.

## R10. One copy.

The same name in two tiers is a silent override with no merge -- there is no `extends:`, no partial frontmatter override.
Fix by deleting, never by syncing.

*Failure it prevents:* three copies of one skill drifting apart, and a project agent silently shadowing a user-level one of the same name.

## R11. A user-tier skill works in a repo that has never seen it.

No pre-existing directory, no config file, no setup step.
This is what makes the tier pluggable: a change lands once and every project has it, including one created tomorrow.

*Failure it prevents:* a hoisted skill that assumes the repo it came from -- hardcoded paths, a `docs/` layout that does not exist yet, a reference to a skill that was deleted.

## R12. Verify under the sandbox, not just in a terminal.

Tools that read credentials from a keyring, a socket, or the session bus behave differently for an agent than for you.
A skill that shells out to one is not working until it has been run the way an agent will run it.

*Failure it prevents:* `gh`-dependent skills that pass by hand and fail for every subagent, indistinguishably from the tool being broken.

## R13. A read-only agent is a convention it keeps, not a cage.

Three frontmatter mechanisms look binding and are not (tested, v2.1.223): `permissionMode: plan` does not stop a subagent writing or deleting through Bash; every parenthesised specifier in `tools:` is silently stripped to the bare tool, including the documented `Agent(name)` form; and `model:` is a default the caller's `model` argument overrides.
The first two fail open.

So: set `disallowedTools: Write, Edit`, and state the contract in the body's first paragraph, naming the obvious loophole -- no shell redirect standing in for Write.
The rest rests on the agent.
The session sandbox is real enforcement but session-wide, so it cannot separate a read-only agent from its caller.

*Failure it prevents:* believing an agent is read-only because its frontmatter says something that was never parsed, or that its model is fixed because the frontmatter names one.

## R14. Skill when it is knowledge for Claude, doc when it is user-facing.

A skill exists to make Claude act correctly.
A doc exists for a person to read.
Audience decides the form -- load mechanics change with the tooling, audience does not.
A skill's supporting files follow the skill: they are knowledge, shelved where it can reach them, not documentation that happens to live there.

A project's own state -- where its requirements, plan and notes live, what command verifies it -- is user-facing, so it is a doc in `docs/`.

*Failure it prevents:* project state buried under `.claude/` where someone returning to the repo will not find it, and reference material for Claude filed in `docs/` where it competes with the project's own documentation.

## R15. Tighter than prose, looser than a code comment.

R8 splits rule from commentary.
This is how the rule itself gets worded: an instruction someone has to apply cold, without the file it describes in front of them.
That is a higher floor than a comment sitting beside the code it explains -- compress toward it, do not arrive at it.

Cut:

- Restatement of a sibling file.
  A rule repeated in the agent that loads the skill carrying it is R10, one file down.
- Commentary on how the harness behaves, which belongs here (R8).
- Hedges -- "really", "already", "actually", "basically", "essentially" -- and the closing clause that re-sells a rule already stated.

Keep:

- The worked example that shows the shape of a right answer.
- The concrete fallback and the named default, so a caller who supplied neither still lands somewhere known (R4).
- The specific trap, named.
  "Stage by explicit path, never `git add .`" survives compression; "commit carefully" does not.
- The reason, where the reason is what makes the rule applied correctly rather than merely agreed with.

*Failure it prevents:* on one side, bodies drifting into essays -- the rule wrapped in a paragraph about why it exists, paid on every spawn, in a file whose sibling exists to hold that paragraph.
On the other, compression that strips the example or the fallback an agent needed and leaves a slogan it cannot act on.

## R16. One sentence per line.

Prose breaks at sentence boundaries -- never at a column, never only at the paragraph.
A long sentence stays whole on its own line and the editor soft-wraps it; a short one gets its own line too.
Verbatim regardless: YAML frontmatter, fenced code, tables, headings.
A repo whose tracked markdown already holds to another convention keeps it (R4).

*Failure it prevents:* a one-word edit reflowing a whole paragraph, so review sees a rewritten block and cannot tell which sentence actually changed -- and the same paragraph rewrapped to a different width by every agent that touches it.

## R17. A check a machine can decide does not live in prose.

Where a rule is mechanically decidable -- a name collision, a parenthesised specifier, a file that does not parse -- prose asking an agent to check it is the weakest available enforcement.
Mechanize it and delete the prose; do not keep both.

The audit holds what is left: what no mechanism can decide.

*Failure it prevents:* R13's `disallowedTools` promise, which holds only while the agent reads it, where a `PreToolUse` deny would hold regardless.
