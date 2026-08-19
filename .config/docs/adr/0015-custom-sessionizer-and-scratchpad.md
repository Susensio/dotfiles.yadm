# ADR-0015: Keep custom sessionizer and scratchpad instead of sesh and floax

Status: Accepted
Date: 2026-08-13

## Context

`scripts/sessionizer` (161 lines) and `scripts/scratchpad` (72 lines) are hand-rolled session management.
Two off-the-shelf replacements exist and were evaluated to cut in-house maintenance: `sesh` for the sessionizer, `floax` for the scratchpad.

## Decision

Keep the custom scripts; do not adopt either.
`sesh` drives icons/preview from hand-curated `sesh.toml` globs, not the automatic path-based classification `path_to_row` does from `LOOKUP_PATHS` — and its sort order doesn't reproduce "current session sorted last, rest by MRU" without extra config.
`floax` keeps one shared scratch session per server, not one per originating `session_id` — it has no equivalent of the `session-closed` cleanup hook or the per-session isolation `scratchpad` relies on.

## Consequences

Categorization, ordering, and per-session cleanup semantics stay exactly as designed, with no glue code needed to recover behavior a plugin doesn't offer.
Cost: maintenance stays entirely in-house.
`scratchpad` also runs a paired server on a `_scratchpad`-suffixed socket, passing the invoking client explicitly on detach — a bare `detach` resolves an ambient "current client" and fails with "no current client" when that can't be determined unambiguously.
Keeping two servers means reloads and environment pushes must reach both (see [ADR-0017](0017-validate-tmux-on-throwaway-server.md)), and the scripts carry undocumented coupling between how a row is named (`session_name_for_dir`) and how a session is later matched or created.
