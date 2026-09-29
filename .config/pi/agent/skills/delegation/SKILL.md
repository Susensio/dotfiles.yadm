---
name: delegation
description: Routes broad discovery, standalone verification, planned implementation leaves, parallel writers, and reviews required by explicit triggers. Use when any appears; otherwise work directly.
---

# Delegation

Work directly when the target and relevant context are bounded. Delegation buys an independent context but pays a cold start, so use observable task structure rather than estimating tokens.

The roles below describe responsibilities rather than required agent names.
Use the available delegation tool and an agent whose capabilities and permissions fit the brief; state the role in the brief when no matching named agent exists.
If delegation is unavailable or disallowed, work directly and report any required independent review that could not be obtained.

## Route work

Without a plan, keep work local except for broad discovery, web research, bulky evidence, or a test-only task that meets the boundary below. Use independent review only when a trigger below applies.

When a task needs a plan, settle its decisions and route each independent leaf once:

- **Main:** architecture, sequencing, shared interfaces, connective edits, integration, and final correctness.
- **Explorer:** unknown targets, broad retrieval, web research, and evidence collection.
- **Worker:** one settled implementation with defined boundaries, completion criteria, and checks.
- **Tester:** one isolated pass/fail check whose runtime behavior, cost, output volume, parallelism, or need for independent observation merits a separate context.
- **Reviewer:** consequential judgment that automated checks cannot settle.

Verification stays with whoever made the change by default.
Keep focused format, lint, type, build, and test commands local.
Delegate to a tester only when verification is itself a standalone task; give it the target and pass criterion when known.
The tester observes and reports but does not fix.

A worker leaf is ready when no design decision remains, its responsibility does not overlap another active worker, and its result can be checked and integrated independently. If those conditions stop holding, return the decision to the main session instead of improvising.

## Parallel work

Readers can run concurrently.
Give parallel writers disjoint responsibilities and a separate worktree or equivalent isolated checkout each.
Use the harness's documented isolation facility when available; otherwise prepare isolated checkouts before dispatch.
Run writers sequentially when isolated working trees cannot be provided.

Check which revision and local changes each child receives; required inputs must exist in its checkout.
Worktrees created from committed `HEAD` do not include uncommitted main-session changes.
Integrate returned changes before building further work on them.

The main session does not repeat delegated research. It checks the returned evidence and inspects file changes before accepting them.
Keep the main session available while background agents run: continue other work or end the turn; check or steer them when needed.

## Review once

Review the integrated change rather than every worker leaf. Delegate to an independent reviewer when at least one condition holds:

- The user requests independent review.
- The change affects authentication, authorization, secrets, destructive operations, money, or privacy.
- It changes persistent data, migrations, concurrency, or a public API.
- Several worker branches meet at a shared boundary.
- Checks cannot establish an important correctness claim.
- A failure remains unexplained or agents reach conflicting conclusions.

Otherwise, focused and integrated checks are enough.

## Brief the child

State the task, relevant facts, boundaries, prior failed attempts, completion condition, and expected return. The child chooses applicable skills from their descriptions. Name a skill only when its relevance is non-obvious or a previous child missed it.

Require a distilled result with paths or sources. Ask the child to separate commands it ran from conclusions it inferred. Resume an agent only when the follow-up depends on context held by that agent; otherwise start fresh.
