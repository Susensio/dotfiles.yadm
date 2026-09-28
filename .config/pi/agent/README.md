# Pi harness

This directory (`~/.config/pi/agent/`) contains a deliberately small personal Pi harness; `~/.config/pi/README.md` documents what yadm tracks in that tree and what stays ignored.

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
| `worker` | DeepSeek V4.1 Flash |
| `reviewer` | GLM 5.3 Flash |

The worker's 4× usage-limit promo on V4.1 Flash is limited-time; when it ends, re-check whether the tier still beats V4 Flash's quota (13,000 vs 6,500 req/5h) on real leaves.

Benchmark the tiers on representative tasks rather than assuming the models are equivalent.

The dormant `pi-automode` classifier config (`agent/extensions/pi-automode/config.json`, tracked) documents the narrow 0/1 gate tier: `opencode-go/mimo-v2.6-flash`, a parse miss fails closed to manual review, not damage.

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
`agent/prompts/` holds prompt templates — one Markdown file per `/`-command. `/perm-report` runs `extensions/pi-permission-system/report.py` (the deterministic log parser) and briefs this session to turn its findings into `config.json` edits; the script is also runnable directly from a shell.
`settings.json` selects packages, while `subagents.json` removes unused orchestration features.
Runtime credentials, model metadata, package files, and session history are not harness documentation.

## Extensions

The retained packages are:

- `@juicesharp/rpiv-ask-user-question` for structured clarification.
- `@juicesharp/rpiv-todo` for visible task state.
- `@tintinweb/pi-subagents` for background agents, parallel dispatch, and optional worktrees.
- `@juicesharp/rpiv-web-tools` for `web_search` and `web_fetch`.
- `@narumitw/pi-usage` for the footer usage widget.
- `pi-footer` for the configurable statusline footer.
- `@gotgenes/pi-permission-system` for tool-call and path access gating.
- `@mzwing/pi-permission-auto-review` as its authorizer (a `codex-auto-review` pass over each ask decision).

(An earlier gate, `@czottmann/pi-automode`, was replaced by the permission system; see the model-tiers section for its kept classifier config.)

The permission system's ask gate is `*: ask` with a deny list for secrets (`*.env*`, `*.pem`, `*.key`, `~/.ssh/*`, `~/.pi/agent/auth.json`), a deny on `sudo *`, an allow list for common read-mostly shell commands, and per-directory external-directory rules. Its `yoloMode` plus auto-review means an ask resolves through the reviewer model rather than a human prompt unless the policy defers it.

The system's hand-maintained config lives at `extensions/pi-permission-system/config.json`, auto-review's at `extensions/pi-permission-auto-review/config.json`; both are tracked. The permission decision log the system writes to `extensions/pi-permission-system/logs/*.jsonl` is ignored as runtime churn.

Everything else under `extensions/` is tracked:

- `herdr-agent-state.ts` (installed by `herdr integration install pi`, overwritten on every herdr update) and `herdr-ask-user-bridge.ts` pipe ask-user questionnaires and permission-dialog waits onto herdr's `herdr:blocked` channel so a blocked session stops looking like it is still working in herdr.
- `pi-footer.json` is the hand-edited config for the `pi-footer` statusline package.


`bash-readonly/` (loaded by the explorer and tester only, via explicit path) is a read-only-agent prototype in `bash-readonly.ts` + `runner.mjs`.

Its nested `bash-readonly.ts` filename deliberately avoids Pi's automatic `extensions/*.ts` and `extensions/*/index.ts` discovery patterns, so the main session does not load it.

It uses Bubblewrap to mount the host filesystem read-only and an unprivileged OverlayFS to give each command a disposable writable project view.

It also provides writable `/tmp` and cache state so routine checks can create artifacts without changing the host.

Network access remains enabled and is not made read-only by this filesystem boundary.

## Deliberately removed

The harness does not include separate leader and general modes, `pi-plan`, default subagents, fallback agents, workflows, schedules, nested delegation, agent mentions, persistent agent memory, or output transcripts.

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
