---
name: audit-harness
description: Audits the agent harness across the user and project tiers and reports what is broken, duplicated, or never loaded. Use after adding or moving agents, skills or context files, and when an agent ignores a rule you thought was in force.
---

# Harness audit

Read-only.
Report findings; change nothing unless asked afterwards.

The doctrine these checks enforce is in [design-rules.md](design-rules.md).
Each check below names the rules it tests.
A finding that cannot name a rule or a concrete breakage is not a finding.

Scope: `~/.config/agents/` (user tier, symlinked into `~/.claude/`), the repo's own `.claude/` and `CLAUDE.md`, any nested `**/.claude/`, and any nested `**/CLAUDE.md` -- Claude auto-discovers these walking up from cwd, so a stale one in a subpackage is still live.

## How to report a finding

Three parts, or drop it: **where** (file and line), **what breaks** (the consequence, not "this is wrong"), **the fix** (one line).
Mark uncertainty with `?` and say why -- an unusual structure may be deliberate.

## 1. Loadability

*Nothing reports a file that failed to load. Silent on success, silent on failure.*

- Resolve every harness symlink (`readlink -f`).
  A link to an **empty directory** passes `ls -l` and loads nothing.
- Each skill dir has `SKILL.md`; each agent file has parseable frontmatter and a non-empty `description`.
- No `SKILL.md` over 500 lines (`wc -l`).
  Past that, detail belongs in a sibling file the skill loads on demand -- a long SKILL.md pays its whole cost on every invocation, including the parts this task will not use.
- `settings*.json` parse (`jq .`).
  A malformed file is dropped whole, taking every permission and hook in it.
- No agent `tools:`/`disallowedTools:` entry uses a parenthesised specifier — R13.
  `Bash(cmd:*)` and even the documented `Agent(name)` are silently stripped to the bare tool, so the line reads as a restriction and grants everything.
  Neither the file nor the agent listing reports the effective grant.
- Confirm an effective grant by having a spawned agent **use** the tool, never by asking it to list one.
  An agent's account of its own tools is generated text, not a reading of the runtime: one declaring `Grep, Glob` reported neither and used both.
  Withhold whatever would let it reach the answer another way, so an absence means what it looks like.
- Harness files in a repo: tracked, or deliberately ignored?
  `git ls-files --error-unmatch` and `git check-ignore -v`.
  Untracked and un-ignored is one `git clean` from gone.

## 2. Duplication — R10

- The same agent or skill `name` in more than one tier.
  The nearer one wins silently; there is no merge and no warning.
- Text byte-identical between a user-tier file and a project one.
- Two copies of a protocol that should have one home.

## 3. Dead references — R11

*The highest-yield check. Every failure this harness has actually had was one of these.*

- Every skill, agent, path, command and script named in any harness file resolves.
  Include `${CLAUDE_SKILL_DIR}` paths and names in prose.
- Skills reference their own scripts through `${CLAUDE_SKILL_DIR}`, not a bare or cwd-relative path.
- **Liveness, under the sandbox** — R12.
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

## 5. Placement — R1, R2, R3, R9

- User-tier content naming one project's paths, stack or conventions.
- Project content that would be true in any repo.
- An agent whose value is only its prompt text, or that names a domain.
- Content in a context file that should be a skill body, since context files reach every subagent with no opt-out.

## 6. Wording — R8, R15, R16

- A description that labels rather than triggers.
- A rule restated in the agent that loads the skill carrying it, or in a second section of the same file.
- A body explaining how the harness behaves instead of what to do.
- The reverse: a rule compressed past the point of use, its worked example or documented fallback gone.
- Prose wrapped to a column instead of to its sentences — R16.
  Two tells, both greppable: a line ending mid-sentence with the next one continuing it, and a paragraph whose lines all stop within a few columns of each other.
  Frontmatter, fenced code, tables and headings are exempt; report the file, not each line.

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
