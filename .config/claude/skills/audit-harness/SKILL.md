---
name: audit-harness
description: Use after adding or moving agents, skills or context files, changing a hook, check or tool grant, or when an agent ignores a rule. Reports broken, duplicated, unreachable, contradicted or unenforced harness parts.
---

# Harness audit

Read-only.
Report findings; change nothing unless asked afterwards.

Load the `harness-design` skill first: it carries the doctrine and the `R-` slugs below.
A finding that cannot name a rule or a concrete breakage is not a finding.
This file holds what to look for and the command that finds it, and cites the rule by slug instead of restating why it matters.

Scope: `~/.config/claude/` (user tier, where `CLAUDE_CONFIG_DIR` points), the repo's own `.claude/` and context file, any nested `**/.claude/` and nested context file -- Claude discovers these walking up from cwd, so a stale one in a subpackage is still live.
A context file is `AGENTS.md`, or `CLAUDE.md` where a directory keeps one; an `AGENTS.md` beside a `CLAUDE.md` is never read by Claude, which is a finding.
Plus the layers holding a rule: hooks in `settings*.json`, pre-commit config, linter and formatter configs, CI workflows.
A rule is worth what the layer that catches it is worth (R-enforcement), so a harness cannot be judged from its prose alone.

## Enumerate first

Its output is the corpus; every check reads that list, so two runs audit the same harness.

```sh
fd . ~/.config/claude/{agents,skills,rules,hooks} --type f --type l   # user tier, as it is on disk
fd '^(CLAUDE|AGENTS)\.md$' . --hidden --no-ignore
fd . .claude --type f --hidden 2>/dev/null       # project tier, if present
fd '^(settings.*\.json|\.pre-commit-config\.yaml|.*\.ya?ml)$' . --hidden --max-depth 3
```

State the count found at each root.
A root that yields nothing is a finding when the harness references it, and noise otherwise.

## How to report a finding

Three parts, or drop it: **where** (file and line), **what breaks** (the consequence), **the fix** (one line).
Mark uncertainty with `?` and say why -- an unusual structure may be deliberate.

## 1. Loadability

*Two instruments answer this directly; run them first.*

- `claude doctor` from a terminal -- install health, and settings files that fail to parse.
  The richer in-session `/doctor` is the user's to run and paste in; `claude -p "/doctor"` returns nothing.
  Run it **outside the sandbox**: inside, denied paths are bind-mounted to `/dev/null` and reported as invalid settings files.
- An `InstructionsLoaded` hook, which fires as each context file loads and carries `file_path`, `memory_type` (`User`/`Project`), `load_reason` (`session_start`, `path_glob_match`, `nested_traversal`, `include`, `compact`) and `cwd`.
  It reports what actually loaded, in a fresh session and in a subagent -- the only way to settle which tier reached whom.
  Probe with a **fresh** session: a rule added to a running one is not read again.

Then:

- Resolve every harness symlink (`readlink -f`).
  A link to an **empty directory** passes `ls -l` and loads nothing.
- Each skill dir has `SKILL.md`; each agent file has parseable frontmatter and a non-empty `description`.
- No skill's `description` exceeds 1536 characters, past which it is truncated, taking the trigger words with it.
  The roster is budgeted at roughly 1% of the context window; when it overflows, the least-invoked skills' descriptions are dropped first.
  Sum them and report the total: this failure arrives by growth, not by edit.
- No `SKILL.md` over 500 lines (`wc -l`) — `writing-for-agents`.
- `settings*.json` parse (`jq .`); a malformed file is dropped whole, with every permission and hook in it.
- No **subagent** `tools:`/`disallowedTools:` entry uses a parenthesised specifier — R-enforcement.
  A main-thread agent (`claude --agent`) is the exception, where `Agent(name)` is enforced.
- Confirm an effective grant by having a spawned agent **use** the tool — R-probe.
- Every claim about runtime behaviour names the version it was tested against — R-stamp.
- Harness files in a repo are tracked or deliberately ignored: `git ls-files --error-unmatch`, `git check-ignore -v`.

## 2. Duplication — R-one-slot

- The same `name` in more than one tier, resolved silently with no merge.
  A **skill**: personal overrides project, so the project copy is the dead one.
  An **agent**: project overrides user, and among nested project directories the closest to cwd wins.
- Text byte-identical between a user-tier file and a project one.
- Two files answering the same question differently -- a default named twice, a fallback one grants and another forbids.
  Delete one, never reconcile.
- Two copies of a protocol that should have one home.

## 3. Dead references — R-in-time

*The highest-yield check.*

- Every skill, agent, path, command and script named in any harness file resolves, including `${CLAUDE_SKILL_DIR}` paths and names in prose.
- Skills reference their own scripts through `${CLAUDE_SKILL_DIR}`, not a bare or cwd-relative path.
- **Liveness, under the sandbox** — R-probe.
  For each external tool a skill shells out to, run its cheapest real invocation sandboxed, as an agent will.
  Denied paths appear as `/dev/null` character devices, not missing files; confirm any surprising file with the sandbox off before reporting it.

## 4. Orphans

- Harness directories no loader reads -- anything outside `.claude/` and the user tier.
- Files nothing references and nothing loads.
  Name the moment each is read; if there is none, say so.
- Reachability is transitive: a skill referenced only from a file nothing loads is as dead as one referenced nowhere.
  Trace each back to a cold session start: a description that fires, a name in a file that loads, or something a person would type.

## 5. Placement — R-one-slot

- User-tier content naming one project's paths, stack or conventions.
- Project content that would be true in any repo.
- An agent whose value is only its prompt text, or that names a domain.
- Content in a context file that should be a skill body or a path-scoped rule.
- Any file under a `rules/` directory with no `paths:` — it loads at session start and reaches every subagent (probed, v2.1.238), charged to every turn and spawn.

## 6. Wording — R-trigger, writing-for-agents

- A description that labels rather than triggers.
- Context pointers with synonym sprawl or buried triggers.
- A rule restated in the agent that loads the skill carrying it, or in a second section of the same file.
- A body explaining how the harness behaves instead of what to do.
- The reverse: a rule compressed past use, its worked example or fallback gone.
- A step with a fuzzy completion bound inviting premature completion.
- Steering solely by prohibition, with no positive target behaviour.
- A description carrying setup instruction the caller cannot act on -- user-facing doc (R-one-slot), in a slot loaded every session.
- Prose wrapped to a column instead of to its sentences — `rules/markdown.md` carries the convention and exemptions.
  Report the file, not each line.

## 7. Contract — R-fallback

- Each input an agent or skill requires from its caller has a documented default or an explicit stop, never "ask" alone.
- A description that demands what the body defaults, or defaults what the body demands.

## 8. Wiring — R-in-time

*Check 3 asks whether what a file names exists. This walks the graph: what reaches what, in what order, and whether it closes on itself.*

A mismatch already priced as an accepted consequence is not a finding; check the project's decision records first.
A rule knowingly left in a file that reaches every subagent, because a narrower placement would not fire in time, is a decision.

- **An instruction reaching an agent that cannot obey it.**
  Cross every rule in the context file and its imports against the roster's `tools:` lists.
  The fix is a condition on the rule, or a grant.
- **A handoff the grant does not support.**
  Where one file tells an agent to spawn another, the named agent exists and the spawner holds `Agent`.
- **A scripted handoff with an incomplete brief.**
  A prescribed spawn carries every input the target's description marks required (R-fallback).
- **Knowledge arriving after the decision it governs.**
  A file to read *before* X, triggered by X happening.
  Either something earlier carries the trigger, or the content moves to a slot that loads unconditionally.
- **A cycle.**
  Two files each naming the other to read first; an agent whose brief routes work back to its spawner.
  Report which end should be the entry.
- **One concept under two names.**
  Grep the old name: a rename reaches the file that was open and stops there.

## 9. Enforcement — R-enforcement

*Every other check asks what the harness says. This asks what happens when an agent ignores it.*

Only rules R-enforcement calls decidable reach this section; "an agent never names a domain" and wording rules stay in prose because nothing else can hold them.
A harness governing no build has no ladder to climb -- say that once, and skip to the hook checks.

- A decidable rule left in prose — R-enforcement.
  Name the mechanism: the glob a `paths:` rule would carry, the `PreToolUse` matcher, the CI check.
  Where naming it takes more than a line, the rule is not decidable.
- **A hook that cannot speak.**
  A `PostToolUse` hook printing to stdout and exiting 0 reaches the debug log, never the transcript (tested, v2.1.223).
  Feedback needs `hookSpecificOutput.additionalContext` as JSON on stdout, or exit 2 to surface stderr.
- **A matcher that never fires.**
  One on `Edit` misses `Write`, and edits made through the shell arrive as `Bash`.
  Decide by running the hook against a sample payload, not by reading the pattern.
- **An enforcer the agent can edit.**
  For each config a check reads -- linter, formatter, hook script, CI workflow -- name what stops an agent turning a red check green by editing it.
  Nothing is the finding.
- A message that reports the violation without the fix or the rule behind it — R-enforcement.
- **The completion gate.**
  Name what decides work is done; where that is the agent's own judgement, name the command that should.

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

## Checks
<every numbered check, one line each, none omitted:
 <n>. <name> — pass | fail (see Findings) | not-run: <why>>
```

A check that could not be run reads like one that passed unless it says `not-run`; a quietly dropped check is not an answer.
Deduplicate to root cause first: one dead symlink orphaning nine skills is one finding.
Never drop a finding past the tenth silently.
