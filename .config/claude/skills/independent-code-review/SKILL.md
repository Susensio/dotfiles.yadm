---
name: independent-code-review
user-invocable: false
description: Codex's independent review of a completed, committed behaviour-changing feature. Use only when a brief explicitly requests it.
---

# Independent code review

Runs inside a delegated subagent, never inline -- the caller commits the change, then spawns this with the pre-change ref in the brief.
No ref in the brief -- ask the caller rather than guessing one from `git log`.

1. Resolve the codex plugin's install path: `jq -r '.plugins["codex@openai-codex"][0].installPath' ~/.config/claude/plugins/installed_plugins.json`.
   Missing or `null` -- Codex isn't installed; report that back.
2. Read `<installPath>/commands/review.md` for its current foreground invocation, then run the equivalent yourself: `node <installPath>/scripts/codex-companion.mjs review --base <ref-from-brief>`.
   Substitute the resolved install path for `${CLAUDE_PLUGIN_ROOT}` -- see `runtime-facts.md` for why.
   Pass no other arguments: native review rejects focus text.
3. A nonzero exit -- unauthenticated, not set up, out of quota, timed out, any Codex error -- is reported back with the actual stderr text, not paraphrased, not treated as a finding.
   Do not retry within this run.

Return what Codex reports verbatim, distilled of transcript noise but not of content.
Fixing findings, disagreeing with one, and falling back to the caller's judgement on a Codex failure happen after this returns.
