# Runtime facts

What Claude Code actually does, as opposed to what a rule here says it should.
Each line carries how it was established and against which version (R-stamp).
`(probed, …)` means a canary was run; `(tested, …)` means observed in use; `(documented, …)` means the official docs say so.

A stamp well behind `claude --version` marks a line to re-probe, not one to trust.
Correct a line here rather than in the file that cites it -- that is the whole reason this file exists.

## What reaches a subagent

- A rule under `rules/` with no `paths:` loads at session start and reaches **every** subagent, with no opt-out (probed, v2.1.238).
  Verified by canary, with a non-matching `paths:` as the control: the scoped one is withheld from the subagent, the unscoped one is not.
- A path-scoped rule fires when the `Read` tool touches a matching path, and **not** on `Write`, `Edit`, or an edit made through the shell (documented, v2.1.238).
  So the rule governing how a file is authored never fires on authoring a new one.
  Tracked upstream in anthropics/claude-code#88565, which is open and widest in scope; #63142 and #72688 stated it precisely and were closed by the stale bot, not resolved.
- Delivery is once per session per rule, not once per matching `Read` (probed, v2.1.238).
  In one session: `fish.md`, `markdown.md` and `python.md` each fired its `system-reminder` on the first `Read` of a matching path and stayed silent on a second, different, later-matching path (`tree.fish` then `tool.fish`; `SKILL.md` then `BACKLOG.md`).
  So a hook adding the `Write`/`Edit` trigger the previous line lacks should dedupe the same way -- one delivery per rule per session -- to match the existing behaviour rather than nagging on every write, *unless* the hook can key dedup per agent instead (next line) -- that reaches every subagent once, which per-session dedup structurally cannot.
- A `PreToolUse` payload's `session_id` and `transcript_path` are both byte-identical between the main thread and every one of its subagents; only `agent_id` differs, present on a subagent's payload and absent on the main thread's (probed, v2.1.238).
  So a hook deduping on `session_id` or `transcript_path` alone delivers to whichever agent writes first and silently skips every other agent in the session -- the `developer`/`documenter` agents that do most of a session's actual Writes chief among them.
  Key dedup on `agent_id` (falling back to `session_id` for the main thread, which carries none) to reach each agent once instead.
- A subagent's initial context carries the whole `CLAUDE.md` hierarchy the main conversation loads, project rules included (documented, v2.1.238).
- `SessionStart` `additionalContext` reaches the main thread only; a spawned subagent never receives it (probed, v2.1.238).
  Two runs, with a control confirming the hook fired and the main thread had it.
- A `PreToolUse` hook fires on a subagent's own tool calls, and its `additionalContext` reaches that subagent's transcript (probed, v2.1.238).
  Verified with a qualifying `grep -r` and a qualifying `find -name` inside a subagent, against a non-qualifying command as control.
  So a hook delivers into a subagent per tool call, never at spawn.

## Grants and frontmatter

- `Bash(cmd:*)` is stripped to the bare tool wherever it appears (tested, v2.1.223).
- `Agent(name)` is stripped in a subagent definition -- the type list inside the parentheses is ignored -- and enforced on a main-thread agent launched with `claude --agent` (documented, v2.1.238).
  `permissions.deny` with `Agent(other-agent)` is the mechanism that does restrict a subagent's spawning.
- `permissionMode: plan` does not stop a subagent writing or deleting through `Bash` (tested, v2.1.223).
- `model:` is a default the caller's `model` argument overrides (tested, v2.1.223).
- `memory:` force-enables `Read`, `Write` and `Edit` (tested, v2.1.223).
- `Grep` and `Glob` are absent from the main session because an empty `tengu_non_deferrable_builtins` flag makes built-ins deferrable (anthropics/claude-code#86971), while a subagent that declares them gets them.
  A tool missing from the session's own list is no evidence it is missing from an agent that asked for it.

## Skills: reach and cost

- `disable-model-invocation: true` removes the skill from the model's reach entirely -- main thread and subagent alike -- and its description leaves the always-loaded roster (documented, v2.1.238).
  `/name` still works.
- `user-invocable: false` removes only the `/` menu entry; the model keeps its reach and the description keeps costing tokens (documented, v2.1.238).
- A skill with `disable-model-invocation: true` **cannot** be preloaded through a subagent's `skills:` field, because preloading draws from the same pool the model can invoke (documented, v2.1.238).
- Preloading is the subagent definition's own frontmatter, fixed at authoring time.
  A caller has no spawn-time parameter for attaching a skill; naming it in the brief is the only other route, and that needs model-invocability (documented, v2.1.238).
- `skills:` fires when the agent is **spawned**, and not when the same definition is launched as the main agent with `--agent <name>` (tested, v2.1.238).
  A spawned `developer` carrying `skills: [coding]` received the body as an `isMeta` message before its first turn, having never called `Skill`; a launched `leader` carrying `skills: [project-docs, delegation]` received nothing until it invoked the skill itself.
  So a launch-only agent's `skills:` field is inert, and whatever it names has to arrive by a trigger instead.
- `SessionStart` fires with `source` of `startup`, `clear`, `resume` or `compact`, and `/clear` wipes the transcript along with anything injected into it (probed, v2.1.238).
  Two trials of `claude --agent leader`: before `/clear` it answered from the injected `project-docs` body; after, both said they had not read the skill this session.
  So a hook injecting an agent's `skills:` must fire on `clear` as well as `startup`, or a launched agent silently continues without what its own definition names.
- Whether compaction preserves an injected skill body is untested and deliberately left so: `CLAUDE.md` is re-injected from disk and names the skill, so the on-demand path still reaches it, and re-injecting ~9 kB per compaction would work against the compaction.
  A probe here would change nothing either way, which is why there is no result to date.

- A preloaded skill satisfies an instruction to read it, so the two do not double up in practice: five spawned `developer`s were each told "Read the `coding` skill" in the brief and none called `Skill(coding)` (tested, v2.1.238).
  Nothing enforces that -- a `Skill` call on a preloaded skill is not deduplicated, it simply does not get made.
  The preload does re-fire after an interrupt: one agent stopped with `TaskStop` and continued carried the same 5529-character body twice.
  Whether a `SendMessage` resume re-injects it too is untested.
- `skillOverrides` in `settings.json` takes `on` | `name-only` | `user-invocable-only` | `off` per skill name.
  Both `user-invocable-only` and `off` drop the description from context; `off` also removes it from `/` autocomplete.
  It does not apply to plugin skills, which are managed through `/plugin` (documented, v2.1.238).
- A `description` is truncated at 1536 characters (`skillListingMaxDescChars`), and the roster as a whole is budgeted at 1% of the context window (`skillListingBudgetFraction`).
  On overflow, full descriptions are dropped starting with the least-invoked skill (documented, v2.1.238).

## `permissions.deny` for Bash

All probed at v2.1.238, against a throwaway `CLAUDE_CONFIG_DIR`.

- `*` is **not** a glob wildcard inside a `Bash(...)` specifier; only the trailing `:*` is special syntax.
  A mid-string `*` matches nothing -- `Bash(git push*--force*:*)` fails even on plain `git push --force`.
  So a deny rule cannot express "this flag anywhere after that subcommand", or "any path to this binary".
- The engine **does** split a compound command on `&&`, `;` and newline, and evaluates each segment: `Bash(cd:*)` blocks `ls && cd /tmp`.
- It **does** strip a leading `sudo` and evaluate the wrapped command.
- It does **not** see into a quoted interpreter argument: `sh -c 'cd /tmp'` passes a `Bash(cd:*)` deny.
- A denial reaches the model as `Permission to use Bash with command <command> has been denied.` and nothing else -- no rule name, no reason, no alternative.
  A rule whose value is in explaining the fix therefore belongs in a `PreToolUse` hook, whose message the model does read.
- Because the match is a literal prefix, a rule naming a flag only catches that flag in the position it names.
  `Bash(git push --force:*)` blocks `git push --force origin main` and misses `git push origin main --force`; enumerating the misses needs one entry per remote, branch and flag spelling, so it goes stale the next time you cut a branch.
  Measured against eleven forms a model writes unprompted: flag-position entries 5/11, `Bash(git push:*)` plus `Bash(yadm push:*)` 9/11 (missing only `git -C <path> push --force` and an absolute path to the binary).
  Denying the verb rather than the flag is what makes a rule branch-agnostic, at the price of the safe uses of that verb.

## Plugins

- `${CLAUDE_PLUGIN_ROOT}` is unset outside a plugin's own registered command, agent or hook -- an agent that reads such a file and copies its invocation verbatim must resolve the plugin's install path itself and substitute it in (probed, v2.1.238, against `codex@openai-codex`).

## The sandbox

- A `cd <dir> && <cmd>` prefix does **not** defeat sandbox auto-approval (probed, v2.1.238).
  With `sandbox.enabled` and `autoAllowBashIfSandboxed`, matched pairs differing only in the `cd` were identical across three repetitions each: no denial, no prompt, both forms sandboxed the same way.
  A write outside `allowWrite` was silently sandboxed to a read-only filesystem in both forms, rather than stopped at the permission layer.
  A `bash-guard` rule was built on the opposite claim and cost two agents an `env -C` detour before this was probed -- one of which produced a real isolation leak.
  It is deleted; the lesson it leaves is R-stamp's, that an unprobed premise is worth less than the rule resting on it.

## Hooks

- A `PostToolUse` hook printing to stdout and exiting 0 tells the model nothing: that stdout reaches the debug log, never the transcript (tested, v2.1.223).
  Feedback needs `hookSpecificOutput.additionalContext` as JSON on stdout, or exit 2 to surface stderr.
- `hookSpecificOutput` requires `hookEventName` beside it; a top-level `additionalContext` fails schema validation and is discarded in silence (tested, v2.1.223).
- A `SessionStart` payload names the launched agent in `agent_type` -- `"leader"` under `--agent leader` -- and omits the key entirely on a default launch, so its absence is the test for one (probed, v2.1.238).
  Alongside it: `session_id`, `transcript_path`, `cwd`, `hook_event_name`, and `source`, which read `startup` on a `-p` launch.
- `additionalContext` carrying a skill body suppresses that skill's later `Skill` call: 0/5 runs called it with the hook against 5/5 without (probed, v2.1.238).
  The body alone does it; the native preload's `<command-name>`/`<skill-format>` marker block is not needed, and the injection lands as an `attachment` record of type `hook_additional_context` rather than the `isMeta` user message the native paths produce.
  Suppression is the model reading it as known, not an enforced dedup -- nothing stops a second load (see below).
- Loading a skill twice injects the body twice; there is no deduplication (tested, v2.1.238).
  Observed where an agent called `Skill` on the same skill twice in one session -- `git-commit` at 2808 and 2815 characters, `tmux_helper` at records 13 and 1100.
