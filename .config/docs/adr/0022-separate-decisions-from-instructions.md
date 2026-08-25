# ADR-0022: Separate architectural decisions from operational instructions

Status: Accepted
Date: 2026-08-15

## Context

Knowledge accumulates from several places: decisions worth recording, the current shape of the setup, day-to-day operating rules, and one-off things an agent is told to remember.
Left unrouted, all of it tends to land wherever an agent happens to be writing — auto-memory, a comment, an instructions file — which scatters related facts and lets the same fact get duplicated in two places that then drift apart.

## Decision

Four destinations, one routing rule each.
`docs/adr/`, via the `adr` skill, for architecturally significant decisions — why the setup got this way, and only when it changes how the system is built or reverses a prior decision.
A topic doc in `docs/` for a subsystem whose current shape is too tangled to re-derive from the config that implements it.
`ENVIRONMENT_ARCHITECTURE.md` is the instance that exists, and covers environment-variable flow only.
`CLAUDE.md` files for how to work in a given part of the repo.
Agent memory only as a fallback, when a piece of knowledge fits none of the other three.

## Consequences

Each kind of knowledge has one home instead of several candidates; asking "why is it built this way" means reading ADRs, not memory.
Reduces duplication — a fact recorded once doesn't need reconciling against a second copy.

Cost: every new piece of knowledge needs a routing judgment before it's written down, and that judgment can be wrong.
The boundary between "what it is" (`ENVIRONMENT_ARCHITECTURE.md`) and "why" (ADRs) needs active maintenance, or the two drift into restating each other.
The rule only holds if the agent applying it checks — nothing enforces the routing mechanically.

## Corrections

2026-08-25: the routing line named `ENVIRONMENT_ARCHITECTURE.md` as the destination for "what the setup is now".
That doc explains environment-variable flow and never held the wider brief, so the line named a single topic doc as if it were the category.
It now names the category and cites that doc as its instance; the four destinations and their routing are unchanged.
