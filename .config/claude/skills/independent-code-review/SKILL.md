---
name: independent-code-review
user-invocable: false
description: Gets Codex's independent review of a completed, committed feature that changes behaviour, and returns its findings verbatim. Use only when the brief explicitly requests it, once the feature's last commit is in -- never per commit, task, documentation change or chore.
---

# Independent code review

Runs inside a delegated subagent, never inline -- the caller commits the change, then spawns this with the pre-change ref already in the brief.
No ref in the brief -- ask the caller rather than guessing one from `git log`.

1. Resolve the codex plugin's install path: `jq -r '.plugins["codex@openai-codex"][0].installPath' ~/.config/claude/plugins/installed_plugins.json`.
   Missing or `null` -- Codex isn't installed; report that back rather than stalling.
2. Read `<installPath>/commands/review.md` for its current foreground invocation, then run the equivalent yourself: `node <installPath>/scripts/codex-companion.mjs review --base <ref-from-brief>`.
   Substitute the resolved install path for `${CLAUDE_PLUGIN_ROOT}` -- see `runtime-facts.md` for why.
   Pass no other arguments: native review rejects focus text outright.
3. A nonzero exit -- unauthenticated, not set up, out of quota, timed out, or Codex erroring for any other reason -- gets reported back with the actual stderr text, not paraphrased, not treated as a finding.
   Do not retry the same failure within this run -- one failed attempt is enough to report, and a second attempt against the same quota or auth problem costs a round-trip for the same answer.

Return what Codex reports verbatim, distilled of transcript noise but not of content.
Fixing what it flags, disagreeing with a finding, and falling back to the caller's own judgement on a Codex failure all happen after this returns, not here.
