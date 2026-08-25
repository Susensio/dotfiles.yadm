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
