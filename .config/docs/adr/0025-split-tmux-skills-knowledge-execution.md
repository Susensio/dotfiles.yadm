# ADR-0025: Split tmux skills by knowledge vs execution and generalize the tester

Status: Accepted
Date: 2026-08-16
Supersedes: [ADR-0021](0021-test-tmux-only-on-isolated-throwaway-servers.md)

## Context

ADR-0021 put every tmux test on a throwaway server and named the `tmux-tester`
subagent as the thing that runs it. The knowledge needed to work on tmux and the
protocol needed to test it then accumulated in one skill, `tmux-helper`: variable
expansion, the format vocabulary, the `conf.d/` layout and upstream research
alongside socket isolation, the `tmux-test` wrapper and the nested-server recipe
for visual checks. Any tmux task loaded all of it — an edit to the status line
pulled in 219 lines of visual-testing reference it would never execute, and a
test pulled in config-architecture advice it had no use for. The isolation
protocol itself existed twice, once in the skill and again restated in the
agent body, free to drift apart.

The agent was also welded to one domain by its name. A second domain wanting the
same container — brief a cold agent, run something isolated, get back a verdict
instead of a transcript — would have had to clone the file.

The argument against generalizing was safety: `tmux-tester` stated the
never-touch-live-tmux rule unconditionally at the top of its body, which a cold
agent reads before it can run anything, and a generic agent reaches that rule
only after choosing to load a skill. That argument loses its force once the
testing skill *is* the isolation protocol rather than a section inside a larger
skill, because then no path to running a tmux command bypasses it.

## Decision

Split `tmux-helper` along knowledge versus execution — `tmux-config` holds the
references, the `conf.d/` layout and the research routine; `tmux-testing` owns
the isolation protocol, the `tmux-test` wrapper and the visual-testing recipe —
and replace `tmux-tester` with a domain-agnostic `tester` agent that carries only
the container discipline and loads the domain's testing skill before running
anything.

ADR-0021's isolation rules are unchanged and now live in exactly one file,
`tmux-testing`; this record supersedes it because its Decision named an agent
that no longer exists, not because throwaway-server isolation was reconsidered.

## Consequences

Each container pays only for what it reads: editing config no longer loads the
testing protocol, and testing no longer loads config practice. The isolation
rules have a single copy, so they cannot drift. A second domain that earns a
tester now needs only a testing skill — no second agent, which is what
`CLAUDE.md` previously deferred until a second one earned it.

`references/formats.md`, which nothing had pointed at since it was written, is
reachable from `tmux-config`.

Cost: the isolation protocol now arrives through a skill load rather than the
agent's own body, so an agent that ignores the instruction to load the skill has
nothing else stopping it — the rule is one indirection further from the thing it
governs. The two skills also have to stay disjoint on their descriptions alone,
since neither names the other; if both fire on one task the split costs context
instead of saving it.
