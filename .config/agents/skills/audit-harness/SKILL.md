---
name: audit-harness
description: Audits the agent harness across the user and project tiers and reports what is broken, duplicated, never loaded, reachable from nothing, contradicted by another file, or stated as a rule with nothing enforcing it. Use after adding or moving agents, skills or context files, after changing a hook, a check or an agent's tool grant, and when an agent ignores a rule you thought was in force.
---

# Harness audit

Read-only.
Report findings; change nothing unless asked afterwards.

Load the `harness-design` skill first: it carries the doctrine these checks enforce, and the rule numbers below are its.
Each check names the rules it tests.
A finding that cannot name a rule or a concrete breakage is not a finding.

Scope: `~/.config/agents/` (user tier, symlinked into `~/.claude/`), the repo's own `.claude/` and `CLAUDE.md`, any nested `**/.claude/`, and any nested `**/CLAUDE.md` -- Claude auto-discovers these walking up from cwd, so a stale one in a subpackage is still live.
Plus the layers the harness leans on to hold a rule: hooks in `settings*.json`, pre-commit config, linter and formatter configs, CI workflows.
A rule is worth what the layer that catches it is worth (R3), so a harness cannot be judged from its prose alone.

## How to report a finding

Three parts, or drop it: **where** (file and line), **what breaks** (the consequence, not "this is wrong"), **the fix** (one line).
Mark uncertainty with `?` and say why -- an unusual structure may be deliberate.

## 1. Loadability

*Two instruments answer this directly. Run them first; the manual checks below cover what they miss.*

- `claude doctor` from a terminal -- install health, and settings files that fail to parse. It replaces the `jq .` check below and adds little else; the richer checkup lives in the in-session `/doctor`, which an agent cannot reach (`claude -p "/doctor"` returns nothing), so it is the user's to run and paste in.
  Run it **outside the sandbox**: inside, every path the sandbox denies is bind-mounted to `/dev/null`, and the tool reports each one as an invalid settings file. It invents findings there.
- An `InstructionsLoaded` hook, which fires as each context file loads and carries `file_path`, `memory_type` (`User`/`Project`), `load_reason` (`session_start`, `path_glob_match`, `nested_traversal`, `include`, `compact`) and `cwd`.
  It reports what actually loaded, in a fresh session and in a subagent, which is the only way to settle a question about which tier reached whom.
  Probe with a **fresh** session: a rule added to one already running is not read again, and mistaking that for the rule's own behaviour is the standing trap here.

- Resolve every harness symlink (`readlink -f`).
  A link to an **empty directory** passes `ls -l` and loads nothing.
- Each skill dir has `SKILL.md`; each agent file has parseable frontmatter and a non-empty `description`.
- No `SKILL.md` over 500 lines (`wc -l`) — R1.
- `settings*.json` parse (`jq .`).
  A malformed file is dropped whole, taking every permission and hook in it.
- No **subagent** `tools:`/`disallowedTools:` entry uses a parenthesised specifier — R3.
  `Bash(cmd:*)` is stripped to the bare tool wherever it appears, and `Agent(name)` is stripped in a subagent definition, so the line reads as a restriction and grants everything.
  The exception is a main-thread agent (`claude --agent`), where `Agent(name)` is enforced and a spawn outside the list fails — flagging one there deletes a real restriction.
  Neither the file nor the agent listing reports the effective grant.
- Confirm an effective grant by having a spawned agent **use** the tool, never by asking it to list one — R5.
- Every claim about runtime behaviour names the version it was tested against — R5.
  A stamp well behind `claude --version` is a rule to re-probe, not one to trust.
- Harness files in a repo: tracked, or deliberately ignored?
  `git ls-files --error-unmatch` and `git check-ignore -v`.
  Untracked and un-ignored is one `git clean` from gone.

## 2. Duplication — R1

- The same `name` in more than one tier -- resolved in opposite directions depending on what it is, silently either way, with no merge and no warning.
  A **skill**: personal overrides project, so `~/.claude/skills/x` shadows the repo's own `x` and the project copy is the dead one.
  An **agent**: project overrides user, and among nested project directories the definition closest to the working directory wins.
- Text byte-identical between a user-tier file and a project one.
- Two files answering the same question differently — a default named twice, a fallback one grants and another forbids.
  A divergent duplicate is still one fact in two slots: delete one, never reconcile them.
- Two copies of a protocol that should have one home.

## 3. Dead references — R1

*The highest-yield check. Every failure this harness has actually had was one of these.*

- Every skill, agent, path, command and script named in any harness file resolves.
  Include `${CLAUDE_SKILL_DIR}` paths and names in prose.
- Skills reference their own scripts through `${CLAUDE_SKILL_DIR}`, not a bare or cwd-relative path.
- **Liveness, under the sandbox** — R5.
  For each external tool a skill shells out to, run its cheapest real invocation the way an agent will: sandboxed.
  A tool that authenticates from a keyring or a socket works in a terminal and fails for every agent.
  - Probe with a real call, not a status subcommand.
    `gh auth status` reports failure while `gh search` succeeds, because they read different credentials.
  - Denied paths appear inside the sandbox as `/dev/null` character devices, not as missing files.
    Confirm any surprising file with the sandbox off before reporting it.

## 4. Orphans

- Harness directories no loader reads -- anything outside `.claude/` and the user tier.
- Files nothing references and nothing loads.
  Name the moment each is read; if there is no such moment, say so.
- Reachability is transitive.
  A skill referenced only from a file that nothing loads is as dead as one referenced nowhere, and the reference makes it look alive.
  Trace each back to a cold session start: a description that fires, a name in a file that loads, or something a person would type.

## 5. Placement — R1

- User-tier content naming one project's paths, stack or conventions.
- Project content that would be true in any repo.
- An agent whose value is only its prompt text, or that names a domain.
- Content in a context file that should be a skill body or a path-scoped rule.
- Any file under a `rules/` directory with no `paths:` in its frontmatter — R1.
  It loads like CLAUDE.md but reaches no subagent, so a standard written there is absent from the agent it governs.

## 6. Wording — R2, writing-for-agents

- A description that labels rather than triggers.
- Context pointers carrying synonym sprawl or buried triggers instead of front-loaded trigger words.
- A rule restated in the agent that loads the skill carrying it, or in a second section of the same file.
- A body explaining how the harness behaves instead of what to do.
- The reverse: a rule compressed past the point of use, its worked example or documented fallback gone.
- An action skill step with a fuzzy completion bound inviting premature completion, rather than a checkable binary condition.
- Steering solely by prohibition -- negative guardrails without an explicit positive target behavior.
- A description carrying setup instruction the caller cannot act on -- how to install or configure the thing is user-facing doc (R1), in a slot loaded in every session.
- Prose wrapped to a column instead of to its sentences — R2.
  Two tells, both greppable: a line ending mid-sentence with the next one continuing it, and a paragraph whose lines all stop within a few columns of each other.
  Frontmatter, fenced code, tables and headings are exempt; report the file, not each line.

## 7. Contract — R4

- Each input an agent or skill requires from its caller has a documented default or an explicit stop.
  A file that only ever says "ask" turns every under-specified handoff into a cold round-trip, paid at the caller's expense before any work starts.
- A description demanding what the body defaults, or defaulting what the body demands.
  The two are one contract read from opposite ends; a caller obeys the description and the agent obeys the body.

## 8. Wiring — R7

*Check 3 asks whether what a file names exists. This one walks the graph it forms: what reaches what, in what order, and whether the path ever closes on itself.*

A mismatch already priced as an accepted consequence is not a finding — check the project's decision records before reporting one.
A rule knowingly left in a file that reaches every subagent, because a narrower placement would not fire in time, is a decision, not a defect.

- **An instruction reaching an agent that cannot obey it.**
  Cross every rule in `CLAUDE.md` and its imports, which reach each subagent with no opt-out, against the roster's `tools:` lists.
  A delegation rule arriving at an agent holding no `Agent`, a web-research rule at one holding no `WebFetch`: it improvises around the gap and reports nothing.
  The fix is a condition on the rule, or a grant.
- **A handoff the grant does not support.**
  Where one file tells an agent to spawn another, the named agent exists and the spawning one holds `Agent`.
- **A scripted handoff with an incomplete brief.**
  A file prescribing a spawn carries every input the target's description marks required — `tester` requires what counts as a pass.
  Missing, the chain stalls one round-trip in, paid by the caller before any work starts (R4).
- **Knowledge arriving after the decision it governs.**
  A file whose description says to read it *before* X, triggered by X happening: by the time it loads, the choice it governs is made.
  Either something present earlier carries the trigger, or the content moves to a slot that loads unconditionally.
- **A cycle.**
  Two files each naming the other as the thing to read first; an agent whose brief routes work back to the one that spawned it; a rule telling an agent to hand off the work it exists to do.
  Nothing detects one at runtime — it spends turns, or stalls on a first step that never comes.
  Report which end should be the entry.
- **One concept under two names.**
  Renaming reaches the file that was open and stops there.
  The survivor is silent: an agent greps the name it was taught, finds nothing, and proceeds as though the thing does not exist.

## 9. Enforcement — R3

*Every other check asks what the harness says. This one asks what happens when an agent ignores it.*

Only rules R3 calls decidable reach this section.
"An agent never names a domain" and every rule about wording stay in prose because nothing else can hold them; reporting those as unenforced buries the findings that mean something.
A harness governing no build has no ladder to climb -- say that once, and skip to the hook checks.

- A decidable rule left in prose — R3.
  Name the mechanism, not the aspiration: the glob a `paths:` rule would carry, the `PreToolUse` matcher, the check a CI step would run.
  Where naming it takes more than a line, the rule is not decidable after all and does not belong here.
- **A hook that cannot speak.**
  A `PostToolUse` hook printing to stdout and exiting 0 tells the model nothing: that stdout reaches the debug log, never the transcript (tested, v2.1.223).
  Feedback needs `hookSpecificOutput.additionalContext` as JSON on stdout, or exit 2 to surface stderr.
  Silent on success and silent on failure, the same shape as the frontmatter R3 describes.
- **A matcher that never fires.**
  Check each `matcher` against the tool names it means to catch: one on `Edit` misses `Write`, and file edits made through the shell arrive as `Bash`.
  Decide it by running the hook against a sample payload, not by reading the pattern.
- **An enforcer the agent can edit.**
  For each config a check reads -- linter, formatter, hook script, CI workflow -- name what stops an agent turning a red check green by editing it.
  Nothing is the finding.
- A message that reports the violation without the fix or the rule behind it — R3.
- **The completion gate.**
  Name what decides work is done.
  Where that is the agent's own judgement, name the command that should decide it instead.

## Report

```
## Verdict
<2-3 sentences: what state the harness is in, and the biggest friction point>

## Findings
<ordered by how often each will bite, first ten in full:
 <file:line> — <what's wrong> → <what breaks> → <fix>   [? if uncertain]>

## Also
<everything past the tenth, one line each: <file:line> — <what's wrong>.
 Omit this heading only when there is nothing past the tenth>

## Clean
<which checks passed, one line>
```

Deduplicate to root cause first.
One dead symlink orphaning nine skills is one finding, not nine.

Detail the first ten.
List the remainder under `## Also` — one line each, where and what — and never drop one silently: a caller shown ten of fourteen with no sign of the other four cannot ask for them.
