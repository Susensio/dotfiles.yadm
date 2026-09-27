# Pi harness

This directory contains a deliberately small personal Pi harness.

The design keeps universal behaviour short, loads reusable knowledge through skills, and uses subagents only when an independent context is worth its startup cost.

## Architecture

The normal Pi session is the only entry point.

It owns decisions, sequencing, shared interfaces, integration, and final correctness.

Four subagents provide distinct execution containers:

- `explorer` gathers repository and web evidence with read-only built-ins and a disposable sandboxed shell.
- `worker` implements one settled, independently checkable plan leaf.
- `tester` runs one isolated verification and returns a pass/fail verdict without modifying live state.
- `reviewer` independently judges consequential code or design without implementing fixes.

Their descriptions and prompts remain model-neutral so model tiers can change without redesigning the harness.

## Model tiers

Use the cheapest model likely to complete each execution bundle reliably.
Everything runs on the OpenCode Go subscription; there is no second provider and no model-fallback layer.

| Agents | OpenCode Go |
| --- | --- |
| `explorer`, `tester` | MiMo V2.6 Flash |
| `worker` | DeepSeek V4 Flash |
| `reviewer` | GLM 5.3 Flash |

The automode classifier runs `opencode-go/mimo-v2.6-flash`. Its task is a narrow 0/1 gate behind deterministic tiers, capped at 512/1200 tokens, so a Flash-tier model is enough — and a parse miss fails closed to manual review, not damage.
Benchmark the tiers on representative tasks rather than assuming the models are equivalent.

## Delegation policy

Work directly when the target and relevant context are bounded.

Use an explorer for broad discovery, web research, or bulky evidence.

Use a worker only after design decisions are settled and the brief has clear boundaries and checks.

Keep routine verification with the implementer.
Use a tester when an isolated pass/fail check is a standalone task because of runtime behavior, cost, output volume, parallelism, or the need for independent observation.

Give parallel writers disjoint responsibilities and invoke each with `isolation: "worktree"`.

Worktrees start from committed `HEAD` and cannot see uncommitted main-session changes.

Review the integrated result rather than every worker leaf.

Use a reviewer only when the user requests one or an explicit risk trigger in `skills/delegation/SKILL.md` applies.

## Configuration

`AGENTS.md` holds universal behaviour and pre-routing triggers.
Agent definitions hold execution boundaries; skills hold conditional procedures and preferences.
`settings.json` selects packages, while `subagents.json` removes unused orchestration features.
Runtime credentials, model metadata, package files, and session history are not harness documentation.

## Extensions

The retained packages are:

- `@juicesharp/rpiv-ask-user-question` for structured clarification.
- `@juicesharp/rpiv-todo` for visible task state.
- `@czottmann/pi-automode` for allow, ask, and block guardrails around agent tool calls.
- `@tintinweb/pi-subagents` for background agents, parallel dispatch, and optional worktrees.
- `@juicesharp/rpiv-web-tools` for `web_search` and `web_fetch`.
- `pi-footer` for the configurable statusline footer.

Automode is not a sandbox.

The worker and reviewer explicitly load it in their child sessions because they have raw Bash access.

The explorer and tester instead receive `bash_readonly`, a read-only-agent prototype loaded by an explicit path.

Its nested `bash-readonly.ts` filename deliberately avoids Pi's automatic `extensions/*.ts` and `extensions/*/index.ts` discovery patterns, so the main session does not load it.

It uses Bubblewrap to mount the host filesystem read-only and an unprivileged OverlayFS to give each command a disposable writable project view.

It also provides writable `/tmp` and cache state so routine checks can create artifacts without changing the host.

Network access remains enabled and is not made read-only by this filesystem boundary.

## Deliberately removed

The harness does not include separate leader and general modes, `pi-plan`, default subagents, fallback agents, workflows, schedules, nested delegation, agent mentions, fleet UI, persistent agent memory, or output transcripts.

These features can return only after a repeated observed need justifies their routing, context, and maintenance cost.

## Setup and validation

Run `/web-tools` once to configure a search provider before using `web_search`.

The current harness has been validated for JSON syntax, clean Pi startup without a model call, installed package consistency, configured model resolution, custom reviewer execution, and isolated tester execution.

`bash_readonly` requires Linux with `bubblewrap`, unprivileged user namespaces, and unprivileged OverlayFS support.

The remaining representative checks are:

1. Run an explorer retrieval task after configuring web search.
2. Run a bounded worker implementation task.
3. Run parallel workers in worktrees and integrate their branches.
4. Benchmark the OpenCode Go tier pairs on representative tasks.

Do not expand the harness merely to complete this list.

Change it only in response to observed behaviour, and use `skills/harness-design/SKILL.md` to decide where a justified addition belongs.
