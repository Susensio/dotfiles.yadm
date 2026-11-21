# ADR-0118: Price the Go quota tiers from a live-cost script, not prose frozen at the last sync

Status: Accepted
Date: 2026-11-21

## Context

The `/sync-models` prompt reconciles the model aliases against a freshly fetched catalog, but every quota fact the tier decisions rest on — monthly multipliers, token prices, peak windows, intelligence scores — lived as prose frozen in the `model-alias.json` `$comment` at the moment someone last wrote it by hand.
The Go provider changes these terms without notice: glm-5.3's monthly multiplier moved from $15 to $200 and, by 2026-11-21, to $500 on the endpoint while the docs table still disagreed, and Artificial Analysis had replaced Intelligence Index v4.3.2 with v5.0.1, on which the same models score on a different scale.
A tier re-synced against a fresh catalog could therefore re-order rungs using prices and scores that were months stale, with nothing in the flow able to notice.

The alternatives were to keep the facts in prose and re-read the sources by hand at each sync, to extend the `model-drift` extension to warn about multiplier changes at startup, and to put the fetching in a script the prompt calls.
Hand re-reading had already failed once, which is why the `$comment` disagreed with the live endpoint.
A startup warning would add network I/O and failure modes to every session for facts that only matter when a tier decision is being made, the one time the operator is already looking.

The needed numbers are mechanical: the OpenCode Go models endpoint is unauthenticated JSON with per-model prices, monthly usage per plan and peak multipliers, and the drain arithmetic (blended cost over cap times the 20 percent five-hour share, intelligence divided by drain) is exactly what the operator was recomputing by hand from `hermes`'s quota report.

## Decision

`~/.config/pi/agent/bin/pi-model-cost` fetches the live Go catalog, computes blended cost, five-hour drain and the intelligence-per-drain index for the configured Go models, and prints the table with the index version and read date.
`/sync-models` runs it before proposing edits, and the table's numbers override the `$comment`'s frozen ones; a score the site has not set prints as `n/a` and is never guessed, and models above 25 percent drain are flagged single-prompt-only.
The script derives each Artificial Analysis page slug from the catalog's names and canonical ids, verified against the site's sitemap, and takes the score from the model's own record only, because plain-name matching both misses models (hy4 is listed under a creator prefix) and, on a naive scrape, attributes a neighbouring model's score to the one being priced.

## Consequences

Every sync proposal now argues from numbers fetched the same minute, and a multiplier change the provider makes between syncs is caught at the next one instead of living on in the `$comment`.
The first run already found one: the `$comment` recorded glm-5.3 at a $200 multiplier while the endpoint had raised it to $500.

Accepted limitation: the intelligence scores are scraped from page markup Artificial Analysis does not expose as an API (the old `/api/v2/data/llms/models` is gone), so a redesign of those pages breaks the score column; the quota columns do not depend on it, the script prints `n/a` rather than guessing, and a broken scraper announces itself as a table of `n/a`s.
Accepted limitation: the site throttles bursts of page fetches into 404-shaped shells that still return HTTP 200, so the script pauses between fetches, backs off once, and detects the shell by its missing score markup; a heavier throttle would silently degrade scores to `n/a` for that run.
Accepted limitation: intelligence scores are only comparable within one index version, and the tier ordering in ADR-0103 was calibrated on v4.3.2; the script prints the version beside every table, and any comparison against those older ranks is the operator's judgement, not the script's.
Accepted limitation: the drain arithmetic treats the monthly cap as the divisor ADR-0103 accepted as undocumented from the provider's side, so an unannounced change to the 20/50/100 window split would misstate every drain by the same factor.
