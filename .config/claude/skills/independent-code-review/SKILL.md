---
name: independent-code-review
user-invocable: false
description: How to get Codex's review of a finished, committed, non-trivial change before it counts as done. Use once per change, not per intermediate commit.
---

# Independent code review

1. Before making any change, capture the starting point: `git rev-parse HEAD`.
   Commit the finished change (through `git-commit`) before running this -- a review scoped by `--base` sees committed history only, and an uncommitted diff would fall back to reviewing this repo's whole working tree, which routinely holds unrelated in-flight edits in a dotfiles checkout.
2. Resolve the codex plugin's install path: `jq -r '.plugins["codex@openai-codex"][0].installPath' ~/.config/claude/plugins/installed_plugins.json`.
   Missing or `null` -- Codex isn't installed, say so and fall back to your own read rather than stalling.
3. Read `<installPath>/commands/review.md` for its current foreground invocation, then run the equivalent yourself: `node <installPath>/scripts/codex-companion.mjs review --base <ref-from-step-1>`.
   Substitute the resolved install path for `${CLAUDE_PLUGIN_ROOT}` -- see `runtime-facts.md` for why.
   Pass no other arguments: native review rejects focus text outright.
4. A nonzero exit -- unauthenticated, not set up, out of quota, timed out, or Codex erroring for any other reason -- gets reported with the actual stderr text, not paraphrased.
   Fall back to your own judgement and finish the change; a Codex failure is not a reason to leave the change undone or unreported.
   Do not retry the same failure within this run -- one failed attempt is enough to fall back on, and a second attempt against the same quota or auth problem costs a round-trip for the same answer.

Treat what comes back like a linter's output: fix what it flags, and say plainly where you disagree rather than dropping a finding silently.
